source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "pg", "~> 1.5"
gem "puma", ">= 6.0"
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[ windows jruby ]

gem "figaro"
gem "rack-cors"
gem "jwt"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end
