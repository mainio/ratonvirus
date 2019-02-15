# frozen_string_literal: true

require "rspec/core/rake_task"

# Exclude integration tests
RSpec::Core::RakeTask.new(:spec_unit) do |t|
  t.verbose = false
  t.exclude_pattern = "spec/integration/*_spec.rb"
end

# Run all tests, with coverage report
RSpec::Core::RakeTask.new(:coverage) do |t|
  ENV["CODECOV"] = "1"
  t.verbose = false
end

# Run all tests, include all
RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
end

# Run both by default
task default: [:spec_unit, :spec, :coverage]
