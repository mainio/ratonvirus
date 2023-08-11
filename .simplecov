# frozen_string_literal: true

SimpleCov.start do
  add_filter "lib/ratonvirus/version.rb"
  add_filter "lib/ratonvirus/engine.rb"
  add_filter "spec/"
end

SimpleCov.command_name ENV["COMMAND_NAME"] || File.basename(Dir.pwd)

SimpleCov.merge_timeout 1800

if ENV["CI"]
  require "simplecov-cobertura"
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
end
