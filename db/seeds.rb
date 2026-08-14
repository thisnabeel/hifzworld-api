english = TranslationSet.find_or_create_by!(language: "en", translator: "natadarrab") do |set|
  set.display_name = "English (natadarrab)"
  set.is_default = true
end
english.update!(is_default: true) unless english.is_default?

TranslationSet.find_or_create_by!(language: "ur", translator: "natadarrab") do |set|
  set.display_name = "Urdu (natadarrab)"
  set.is_default = false
end
