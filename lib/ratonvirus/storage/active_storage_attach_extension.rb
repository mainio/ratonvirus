# frozen_string_literal: true

module Ratonvirus
  module Storage
    module ActiveStorageAttachExtension
      def attach(*attachables)
        attachables = attachables.flatten

        Ratonvirus::Storage::ActiveStorage.register_attachables(
          record, name, attachables.flatten
        )

        super
      end
    end
  end
end
