# frozen_string_literal: true

# Test runtime dependencies to be able to test the validator
require "active_model"
require "active_storage"
require_relative "../app/validators/antivirus_validator"
require "tempfile"

# Default spec helper
require "spec_helper"

# Add the translations load path for I18n
base_path = File.expand_path(File.dirname(File.dirname(__FILE__)))
I18n.load_path << Dir[base_path + "/config/locales/*.yml"]
