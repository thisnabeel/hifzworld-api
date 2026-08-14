#!/usr/bin/env python3
"""Scrape natadarrab Heroku search API into a resumable JSON file."""

from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

AYAH_COUNTS = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6,
]
URL = "https://natadarrab-api-7-4298623a0ae3.herokuapp.com/revelations/search.json"
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "db" / "data" / "natadarrab_translations.json"
WORKERS = int(os.environ.get("WORKERS", "6"))


def all_keys() -> list[str]:
    keys = []
    for surah, count in enumerate(AYAH_COUNTS, start=1):
        for ayah in range(1, count + 1):
            keys.append(f"{surah}:{ayah}")
    return keys


def fetch(key: str) -> tuple[str, dict[str, str]]:
    body = json.dumps({"verses": key}).encode()
    req = urllib.request.Request(URL, data=body, headers={"Content-Type": "application/json"})
    last_error = None
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                payload = json.loads(resp.read().decode())
            row = payload[0] if isinstance(payload, list) else payload
            translation = (row or {}).get("translation") or {}
            return key, {
                "english": (translation.get("english") or "").strip(),
                "urdu": (translation.get("urdu") or "").strip(),
            }
        except Exception as exc:  # noqa: BLE001
            last_error = exc
            time.sleep(0.4 * (attempt + 1))
    raise RuntimeError(f"{key}: {last_error}")


def main() -> int:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    data: dict[str, dict[str, str]] = {}
    if OUT.exists():
        data = json.loads(OUT.read_text())
    keys = all_keys()
    missing = [
        key
        for key in keys
        if not data.get(key, {}).get("english") or not data.get(key, {}).get("urdu")
    ]
    print(f"Have {len(data)} rows; missing {len(missing)} of {len(keys)}", flush=True)
    if not missing:
        print("COMPLETE", flush=True)
        return 0

    done = 0
    with ThreadPoolExecutor(max_workers=WORKERS) as pool:
        futures = {pool.submit(fetch, key): key for key in missing}
        for future in as_completed(futures):
            key, langs = future.result()
            data[key] = langs
            done += 1
            if done % 25 == 0 or done == len(missing):
                OUT.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")))
                print(f"{done}/{len(missing)} last={key} total={len(data)}", flush=True)
    OUT.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")))
    complete = all(
        data.get(key, {}).get("english") and data.get(key, {}).get("urdu") for key in keys
    )
    print("COMPLETE" if complete else f"INCOMPLETE {len(data)}/{len(keys)}", flush=True)
    return 0 if complete else 1


if __name__ == "__main__":
    sys.exit(main())
