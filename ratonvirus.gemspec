# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ratonvirus/version"

Gem::Specification.new do |spec|
  spec.name = "ratonvirus"
  spec.version = Ratonvirus::VERSION
  spec.required_ruby_version = ">= 3.2"
  spec.authors = ["Antti Hukkanen"]
  spec.email = ["antti.hukkanen@mainiotech.fi"]

  spec.summary = "Provides antivirus checks for Rails."
  spec.description = "Adds antivirus check capability for Rails applications."
  spec.homepage = "https://github.com/mainio/ratonvirus"
  spec.license = "MIT"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "{app,config,lib}/**/*",
    "CHANGELOG.md",
    "LICENSE",
    "README.md"
  ]

  spec.require_paths = ["lib"]

  # The activesupport dependency is used for the string manipulations done in
  # the Ratonvirus main module through ActiveSupport::Inflector.
  spec.add_dependency "activesupport", "~> 8.0"
end
