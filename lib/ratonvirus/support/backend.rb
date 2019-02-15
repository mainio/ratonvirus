# frozen_string_literal: true

module Ratonvirus
  module Support
    # The backend implementation allows us to set different backends on the main
    # Ratonvirus configuration, e.g. scanner and storage backends. This makes
    # the library agnostic of the actual implementation of these both and allows
    # the developer to configure
    #
    # The solution is a bit hacky monkey patch type of solution as it adds code
    # to the underlying implementation through class_eval. The reason for this
    # is to define arbitrary getter, setter and destroye methods that are nicer
    # to use for the user. Wrapping this functionality to its own module
    # makes the resulting code less prone to errors as all of the backends are
    # defined exactly the same way.
    #
    # Modifying this may be tough, so be sure to test properly in case you make
    # any modifications.
    module Backend
      # First argument "backend_cls":
      #   The subclass that refers to the backend's namespace, e.g.
      #   `"Scanner"`.
      #
      # Second argument "backend_type":
      #   The backend type in the given namespace, e.g. `:eicar`
      #
      # The returned result will be e.g.
      #   Ratonvirus::Scanner::Eicar
      #   Ratonvirus::Storage::ActiveStorage
      def backend_class(backend_cls, backend_type)
        return backend_type if backend_type.is_a?(Class)

        subclass = ActiveSupport::Inflector.camelize(backend_type.to_s)
        ActiveSupport::Inflector.constantize(
          "#{name}::#{backend_cls}::#{subclass}"
        )
      end

      private

      # Defines the "backend" methods.
      #
      # For example, this:
      #   define_backend :foo, 'Foo'
      #
      # Would define the following methods:
      #   # Getter for foo
      #   def self.foo
      #     @foo ||= create_foo
      #   end
      #
      #   # Setter for foo
      #   def self.foo=(foo_type)
      #     set_backend(
      #       :foo,
      #       'Foo',
      #       foo_type
      #     )
      #   end
      #
      #   # Destroys the currently active foo.
      #   # The foo is re-initialized when the getter is called.
      #   def self.destroy_foo
      #     @foo = nil
      #   end
      #
      #   private
      #     def self.create_foo
      #       if @foo_defs.nil?
      #         raise NotDefinedError.new("Foo not defined!")
      #       end
      #
      #       @foo_defs[:klass].new(@foo_defs[:config])
      #     end
      #
      # Usage (getter):
      #   Ratonvirus.foo
      #
      # Usage (setter):
      #   Ratonvirus.foo = :bar
      #   Ratonvirus.foo = :bar, {option: 'value'}
      #   Ratonvirus.foo = Ratonvirus::Foo::Bar.new
      #   Ratonvirus.foo = Ratonvirus::Foo::Bar.new({option: 'value'})
      #
      # Usage (destroyer):
      #   Ratonvirus.destroy_foo
      #
      def define_backend(backend_type, backend_subclass)
        class_eval <<-CODE, __FILE__, __LINE__ + 1
          # Getter for #{backend_type}
          def self.#{backend_type}
            @#{backend_type} ||= create_#{backend_type}
          end

          # Setter for #{backend_type}
          def self.#{backend_type}=(#{backend_type}_value)
            set_backend(
              :#{backend_type},
              "#{backend_subclass}",
              #{backend_type}_value
            )
          end

          # Destroys the currently active #{backend_type}.
          # The #{backend_type} is re-initialized when the getter is called.
          def self.destroy_#{backend_type}
            @#{backend_type} = nil
          end

          # Creates a new backend instance
          # private
          def self.create_#{backend_type}
            if @#{backend_type}_defs.nil?
              raise NotDefinedError.new("#{backend_subclass} not defined!")
            end

            @#{backend_type}_defs[:klass].new(
              @#{backend_type}_defs[:config]
            )
          end
          private_class_method :create_#{backend_type}
        CODE
      end

      # Sets the backend to local variables for the backend initialization.
      # The goal of this method is to get the following configuration set to
      # local `@x_defs` variable, where 'x' is the type of backend.
      #
      # For example, for a backend with type "scanner", this would be
      # @scanner_defs.
      #
      # The first argument, "backend_type" is the type of backend we are
      # configuring, e.g. `:scanner`.
      #
      # The second argument "backend_cls" is the backend subclass that is
      # used in the module's namespace, e.g. "Scanner". This would refer to
      # subclasses `Ratonvirus::Scanner::...`.
      #
      # The third argument "backend_value" is the actual value the user
      # provided for the setter method, e.g. `:eicar` or
      # `Ratonvirus::Scanner::Eicar.new`. The user may also provide a second
      # argument to the setter method e.g. like
      # `Ratonvirus.scanner = :eicar, {conf: 'option'}`, in which case these
      # both arguments are provided in this argument as an array.
      def set_backend(backend_type, backend_cls, backend_value)
        base_class = backend_class(backend_cls, "Base")

        if backend_value.is_a?(base_class)
          # Set the instance
          instance_variable_set(:"@#{backend_type}", backend_value)

          # Store the class (type) and config for storing them below to local
          # variable in case it needs to be re-initialized at some point.
          subtype = backend_value.class
          config = backend_value.config
        else
          if backend_value.is_a?(Array)
            subtype = backend_value.shift
            config = backend_value.shift || {}

            raise InvalidError, "Invalid #{backend_type} type: #{subtype}" unless subtype.is_a?(Symbol)
          elsif backend_value.is_a?(Symbol)
            subtype = backend_value
            config = {}
          else
            raise InvalidError, "Invalid #{backend_type} provided!"
          end

          # Destroy the current one
          send(:"destroy_#{backend_type}")
        end

        instance_variable_set(
          :"@#{backend_type}_defs",
          klass: backend_class(backend_cls, subtype),
          config: config
        )
      end
    end
  end
end
