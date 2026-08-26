# frozen_string_literal: true

source "https://rubygems.org"

gem "mimemagic", "<0.3.10"

group :development do
  # Basic development dependencies.
  gem "rake", "~> 13.0"
  gem "rspec", "~> 3.0"

  # Rails integration tests
  gem "rspec-rails", "~> 6.0"

  # The following Rails dependencies are needed to test the actual validator to
  # be attached to Active Models. These are not necessary for the basic
  # functionality of this gem and all other parts of the gem should work fine
  # without them. Therefore, only needed as development dependencies.
  gem "activemodel", "~> 8.0"
  gem "activestorage", "~> 8.0"

  # The following dependency is needed to test the CarrierWave storage. This is
  # not required for running this gem without CarrierWave.
  gem "carrierwave", "~> 2.1"

  # Rubocop linter
  gem "rubocop", "~> 1.65"
  gem "rubocop-rspec", "~> 3.0"
end

group :development, :test do
  gem "sqlite3", "~> 2.1.0"
end

group :test do
  gem "simplecov"
  gem "simplecov-cobertura"
end

gemspec
