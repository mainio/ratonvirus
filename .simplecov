# frozen_string_literal: true

if ENV["SIMPLECOV"]
  SimpleCov.skip "lib/ratonvirus/version.rb"
  SimpleCov.skip "lib/ratonvirus/engine.rb"
  SimpleCov.skip "spec/"

  SimpleCov.command_name ENV["COMMAND_NAME"] || File.basename(Dir.pwd)

  SimpleCov.merge_timeout 1800

  if ENV["CI"]
    require "simplecov-cobertura"
    SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
  end
end
