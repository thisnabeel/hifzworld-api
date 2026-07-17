# Hifzworld API

Rails 8.1 API for bundle sharing, live review sessions, and listener mistake marking for the Unzyla iOS app.

## Features

- Sign in with Apple (JWT auth)
- Mushaf bundle CRUD and sharing
- Review sessions (reciter + listener)
- Session mistake marks with ActionCable broadcasts
- Optional LiveKit video room metadata

## Local setup

```bash
cp config/application.yml.example config/application.yml
# Edit DATABASE_URL and JWT_SECRET

bundle install
bin/rails db:create db:migrate
bin/rails server
```

Dev auth bypass (local only):

```bash
# In application.yml
APPLE_AUTH_SKIP_VERIFY: "true"

curl -X POST http://localhost:3000/api/auth/apple \
  -H "Content-Type: application/json" \
  -d '{"apple_sub":"dev-1","display_name":"Dev User","email":"dev@example.com"}'
```

## Railway deploy

1. Create a new service from this repo (Dockerfile builder).
2. Link your Postgres plugin — Railway sets `DATABASE_URL`.
3. Set variables:
   - `JWT_SECRET` — output of `bin/rails secret`
   - `APPLE_CLIENT_ID` — iOS bundle ID
   - `RAILS_MASTER_KEY` — contents of `config/master.key`
   - `RAILS_ENV=production`
   - Optional: `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`
   - Optional: `MIN_APP_VERSION` — marketing version that forces an App Store update (e.g. `1.2.0`); blank = no gate
   - Optional: `IOS_APP_STORE_ID` — numeric App Store ID for the Update button
4. Deploy. Migrations run automatically via `bin/docker-entrypoint`.

Health check: `GET /api/health`
App config (public): `GET /api/app_config` → `{ min_app_version, app_store_id }`

## API overview

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/apple` | Sign in |
| GET | `/api/users/me` | Current user |
| GET | `/api/bundles/mine` | Owned + shared bundles |
| POST | `/api/bundles` | Create bundle |
| POST | `/api/bundles/:id/share` | Share bundle |
| GET | `/api/bundle_shares` | Pending shares |
| POST | `/api/bundle_shares/:id/accept` | Accept share |
| POST | `/api/review_sessions` | Start session |
| POST | `/api/review_sessions/:id/join` | Listener joins |
| POST | `/api/review_sessions/:id/marks` | Create mark |
| GET | `/api/users/me/feedback` | Reciter feedback list |

WebSocket: `/cable?token=JWT` → `ReviewSessionChannel` with `session_id`.
