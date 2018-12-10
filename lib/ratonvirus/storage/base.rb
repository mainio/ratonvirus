module Ratonvirus
  module Storage
    class Base
      attr_reader :config

      def initialize(configuration={})
        @config = configuration.dup

        if respond_to?(:setup)
          setup
        end
      end

      # Default process implementation.
      def process(resource)
        return unless block_given?
        return if resource.nil?

        resource = [resource] unless resource.is_a?(Array)

        resource.each do |asset|
          yield processable(asset)
        end
      end

      def changed?(record, attribute)
        raise NotImplementedError.new(
          "Implement changed? on #{self.class.name}"
        )
      end

      def accept?(resource)
        raise NotImplementedError.new(
          "Implement accept? on #{self.class.name}"
        )
      end

      def asset_path(asset)
        raise NotImplementedError.new(
          "Implement path on #{self.class.name}"
        )
      end

      def asset_remove(asset)
        raise NotImplementedError.new(
          "Implement remove on #{self.class.name}"
        )
      end

      protected
        def processable(asset)
          Processable.new(self, asset)
        end
    end
  end
end
