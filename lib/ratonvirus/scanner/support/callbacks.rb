module Ratonvirus
  module Scanner
    module Support
      # Provides a simple callbacks implementation to be used with the scanners.
      #
      # We cannot use the ActiveSupport::Callbacks because that applies the
      # callbacks to the whole class. We only want to define callbacks on the
      # single instance of a class.
      #
      # Defining new callbacks hooks to the instance:
      #   class Cls
      #     include Ratonvirus::Support::Callbacks
      #
      #     def initialize
      #       define_callbacks :hook
      #     end
      #   end
      #
      # Triggering the callback hooks:
      #   class Cls
      #     # ...
      #     def some_method
      #       run_callbacks :hook, resource do
      #         puts "... do something ..."
      #       end
      #     end
      #     # ...
      #   end
      #
      # Applying functionality to the hooks:
      #   class Cls
      #     def attach_callbacks
      #       before_hook :run_before
      #       after_hook :run_after
      #     end
      #
      #     def run_before
      #       puts "This is run before the hook"
      #     end
      #
      #     def run_after
      #       puts "This is run after the hook"
      #     end
      #   end
      module Callbacks
        private
          def run_callbacks(type, *args, &block)
            if @_callbacks.nil?
              raise NotDefinedError.new("No callbacks defined")
            end
            if @_callbacks[type].nil?
              raise NotDefinedError.new("Callbacks for #{type} not defined")
            end

            run_callback_callables @_callbacks[type][:before], *args
            result = yield *args
            run_callback_callables @_callbacks[type][:after], *args

            result
          end

          def run_callback_callables(callables, *args)
            callables.each do |callable|
              send(callable, *args)
            end
          end

          def define_callbacks(type)
            @_callbacks ||= {}
            @_callbacks[type] ||= {}
            @_callbacks[type][:before] = []
            @_callbacks[type][:after] = []

            define_singleton_method "before_#{type}" do |callable|
              @_callbacks[type][:before] << callable
            end
            define_singleton_method "after_#{type}" do |callable|
              @_callbacks[type][:after] << callable
            end
          end
      end
    end
  end
end
