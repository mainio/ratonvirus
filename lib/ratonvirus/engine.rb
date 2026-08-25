# frozen_string_literal: true

# Binding it to rails to make the app and config folders available in the Rails
# load paths.
module Ratonvirus
  class Engine < ::Rails::Engine
    ::ActiveStorage::Attached::Many.prepend(
      Ratonvirus::Storage::ActiveStorageAttachExtension
    )
  end
end
