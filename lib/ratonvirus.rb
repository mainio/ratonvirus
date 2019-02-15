# frozen_string_literal: true

require "fileutils"
require "active_support"
require "digest"

require_relative "ratonvirus/version"
require_relative "ratonvirus/error"
require_relative "ratonvirus/processable"
require_relative "ratonvirus/support/backend"
require_relative "ratonvirus/scanner/support/callbacks"
require_relative "ratonvirus/scanner/base"
require_relative "ratonvirus/scanner/eicar"
require_relative "ratonvirus/scanner/addon/remove_infected"
require_relative "ratonvirus/storage/base"
require_relative "ratonvirus/storage/filepath"
require_relative "ratonvirus/storage/active_storage"
require_relative "ratonvirus/storage/carrierwave"
require_relative "ratonvirus/storage/multi"

require_relative "ratonvirus/engine" if defined?(Rails)

module Ratonvirus
  extend Ratonvirus::Support::Backend

  # Usage:
  #   Ratonvirus.configure do |config|
  #     config.scanner = :eicar
  #     config.storage = :active_storage
  #     config.addons  = [:remove_infected]
  #   end
  def self.configure
    yield self
  end

  # Usage (set):
  #   Ratonvirus.scanner = :eicar
  #   Ratonvirus.scanner = :eicar, {option: 'value'}
  #   Ratonvirus.scanner = Ratonvirus::Scanner::Eicar.new
  #   Ratonvirus.scanner = Ratonvirus::Scanner::Eicar.new({option: 'value'})
  #
  # Usage (get):
  #   Ratonvirus.scanner
  #
  # Usage (destroy):
  #   Ratonvirus.destroy_scanner
  define_backend :scanner, "Scanner"

  # Usage (set):
  #   Ratonvirus.storage = :active_storage
  #   Ratonvirus.storage = :active_storage, {option: 'value'}
  #   Ratonvirus.storage = Ratonvirus::Storage::ActiveStorage.new
  #   Ratonvirus.storage = Ratonvirus::Storage::ActiveStorage.new({option: 'value'})
  #
  # Usage (get):
  #   Ratonvirus.storage
  #
  # Usage (destroy):
  #   Ratonvirus.destroy_storage
  define_backend :storage, "Storage"

  # Resets Ratonvirus to its initial state and configuration
  def self.reset
    # Default addons
    @addons = [
      ActiveSupport::Inflector.constantize(
        "#{name}::Scanner::Addon::RemoveInfected"
      )
    ]

    destroy_scanner
    destroy_storage
  end

  def self.addons
    @addons
  end

  def self.addons=(addons)
    @addons = []
    addons.each do |addon|
      add_addon addon
    end
  end

  def self.add_addon(addon)
    addon_cls = addon_class(addon)
    @addons << addon_cls unless @addons.include?(addon_cls)
  end

  def self.remove_addon(addon)
    addon_cls = addon_class(addon)
    @addons.delete(addon_cls)
  end

  # private
  def self.addon_class(type)
    return type if type.is_a?(Class)

    subclass = ActiveSupport::Inflector.camelize(type.to_s)
    ActiveSupport::Inflector.constantize(
      "#{name}::Scanner::Addon::#{subclass}"
    )
  end
  private_class_method :addon_class

  # Reset the utility to start with
  reset
end
