source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "pg", "~> 1.6"
gem "json", "~> 2.21"
gem "puma", "~> 8.0"

# JSON serialization
gem "alba", "~> 4.0"
gem "oj", "~> 3.17"

# Background jobs + cron-style scheduling for the daily reminder sweep
gem "sidekiq", "~> 8.1"
gem "sidekiq-cron", "~> 2.4"

# Pagination for the books index
gem "pagy", "~> 43.6"

gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", "~> 1.26", require: false

group :development, :test do
  gem "debug", "~> 1.11", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", "~> 0.9", require: false
  gem "brakeman", "~> 8.0", require: false
  gem "rubocop-rails-omakase", "~> 1.1", require: false

  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails", "~> 6.5"
  gem "faker", "~> 3.8"
  gem "shoulda-matchers", "~> 8.0"
  gem "simplecov", "~> 0.22", require: false
end
