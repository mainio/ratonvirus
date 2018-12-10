# frozen_string_literal: true

require 'rspec/core/rake_task'

# Exlucde integration tests
RSpec::Core::RakeTask.new(:spec_unit) do |t, task_args|
  t.verbose = false
  t.exclude_pattern = 'spec/integration/*_spec.rb'
end

# Run all tests, include all
RSpec::Core::RakeTask.new(:spec) do |t, task_args|
  t.verbose = false
end

# Run both by default
task default: [:spec_unit, :spec]
