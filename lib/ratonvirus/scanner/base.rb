module Ratonvirus
  module Scanner
    class Base
      include Support::Callbacks

      class << self
        def executable?
          false
        end
      end

      attr_reader :config
      attr_reader :errors # Only available after `virus?` has been called.

      def initialize(configuration={})
        @config = default_config.merge!(configuration)

        # Make the following callbacks available:
        # - before_process_scan
        # - before_scan
        # - after_scan
        # - after_process_scan
        #
        # Usage:
        #   module CustomAddon
        #     def self.extended(validator)
        #       validator.before_process_scan :around_scan
        #       validator.before_scan :do_something
        #       validator.after_scan :do_something
        #       validator.before_process_scan :around_scan
        #     end
        #
        #     private
        #       def around_scan(resource)
        #         puts resource.inspect
        #         # Depends on the provided resource, e.g.
        #         # => #<ActiveStorage::Attached::One: ...>
        #         # => #<ActiveStorage::Attached::Many: ...>
        #         # => #<CarrierWave::Uploader::Base: ...>
        #         # => #<File: ...>
        #         # => #<String: ...>
        #       end
        #
        #       def do_something(processable)
        #         puts processable.inspect
        #         # => #<Ratonvirus::Processable: ...>
        #       end
        #   end
        define_callbacks :process_scan # Around the scan for the whole resource
        define_callbacks :scan # The actual scan for individual assets

        setup
      end

      # This method can be overridden in the scanner implementations in case
      # the setup needs to be customized.
      def setup
        if config[:force_availability]
          @available = true
        else
          available?
        end
      end

      def available?
        return @available unless @available.nil?

        @available = self.class.executable?
      end

      # The virus? method runs the scan and returns a boolean indicating
      # whether the scanner rejected the given resource or detected a virus.
      # Scanning is mainly used to detect viruses but the scanner can reject the
      # resource also because of other reasons than it detecting a virus.
      #
      # All these cases, however, should be interpreted as the resource
      # containing a virus because in case there is e.g. a client error, we
      # cannot be sure whether the file contains a virus and therefore it's
      # safer to assume the worst.
      #
      # Possible errors are:
      # - :antivirus_virus_detected - A virus was detected.
      # - :antivirus_file_not_found - The scanner did not find the file for the
      #   given resource.
      # - :antivirus_client_error - There was a client error at the scanner,
      #   e.g. it is temporarily unavailable.
      def virus?(resource)
        prepare

        @errors = []

        run_callbacks :process_scan, resource do
          storage.process(resource) do |processable|
            # In case multiple processables are processed, make sure that the
            # local errors for each scan refer only to that scan.
            errors_before = @errors
            @errors = []

            begin
              scan(processable)
            ensure
              # Make sure that after the scan, the errors are reverted back to
              # all errors.
              @errors = errors_before + @errors
            end
          end
        end

        # Only show unique errors
        errors.uniq!

        errors.any?
      end

      protected
        def default_config
          {
            force_availability: false,
          }
        end

        def storage
          Ratonvirus.storage
        end

        def scan(processable)
          processable.path do |path|
            run_callbacks :scan, processable do
              run_scan(path)
            end
          end
        end

        def run_scan(path)
          raise NotImplementedError.new(
            "Implement run_scan on #{self.class.name}"
          )
        end

      private
        # Prepare is called each time before scanning is run. During the first
        # call to this method, the addons are applied to the scanner instance.
        def prepare
          return if @ready

          Ratonvirus.addons.each do |addon_cls|
            extend addon_cls
          end

          @ready = true
        end
    end
  end
end
