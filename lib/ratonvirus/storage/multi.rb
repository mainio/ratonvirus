module Ratonvirus
  module Storage
    # Multi storage allows the developers to configure multiple storage backends
    # for the application at the same time. For instance, in case the scanner is
    # used for both: scanning the Active Storage resources as well as scanning
    # file paths, they are handled with separate storages.
    #
    # To configure the Multi-storage with two backends, use the following:
    # Ratonvirus.storage = :multi, {storages: [:filepath, :active_storage]}
    class Multi < Base
      # Setup the @storages array with the initialized storage instances.
      def setup
        @storages = []

        if config[:storages].is_a?(Array)
          config[:storages].each do |storage|
            if storage.is_a?(Array)
              type = storage[0]
              storage_config = storage[1]
            else
              type = storage
            end

            cls = Ratonvirus.backend_class('Storage', type)
            @storages << cls.new(storage_config || {})
          end
        end
      end

      # Processing of the resource is handled by the first storage in the list
      # that returns `true` for `accept?(resource)`. Any consequent storages are
      # skipped.
      def process(resource, &block)
        return unless block_given?

        storage_for(resource) do |storage|
          storage.process(resource, &block)
        end
      end

      # Fetch the resource from the record using the attribute and check if any
      # storages accept that resource. If an accepting storage is found, only
      # check `changed?` against that storage. Otherwise, call the `changed?`
      # method passing both given parameters for all storages in order and
      # return in case one of them reports the resource to be changed.
      def changed?(record, attribute)
        resource = record.public_send(attribute)

        storage_for(resource) do |storage|
          return storage.changed?(record, attribute)
        end

        false
      end

      # Check if any of the storages accept the resource.
      def accept?(resource)
        storage_for(resource) do |storage|
          return true
        end

        false
      end

      private
        # Iterates through the @storages array and returns the first storage
        # that accepts the resource.
        def storage_for(resource)
          @storages.each do |storage|
            if storage.accept?(resource)
              yield storage
              return
            end
          end
        end
    end
  end
end
