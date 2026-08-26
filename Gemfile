# frozen_string_literal: true

source "https://rubygems.org"

gem "mimemagic", "<0.3.10"

group :development do
  # Basic development dependencies.
  gem "rake", "~> 13.4"
  gem "rspec", "~> 3.13"

  # Rails integration tests
  gem "rspec-rails", "~> 8.0"

  # The following Rails dependencies are needed to test the actual validator to
  # be attached to Active Models. These are not necessary for the basic
  # functionality of this gem and all other parts of the gem should work fine
  # without them. Therefore, only needed as development dependencies.
  gem "activemodel", "~> 8.0"
  gem "activestorage", "~> 8.0"

  # The following dependency is needed to test the CarrierWave storage. This is
  # not required for running this gem without CarrierWave.
  gem "carrierwave", "~> 3.1"

  # Rubocop linter
  gem "rubocop", "~> 1.90"
  gem "rubocop-rspec", "~> 3.10"
end

group :development, :test do
  gem "sqlite3", "~> 2.9.6"
end

group :test do
  gem "simplecov"
  gem "simplecov-cobertura"
end

gemspec
