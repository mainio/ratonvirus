# frozen_string_literal: true

module Ratonvirus
  module Storage
    class Base
      attr_reader :config

      def initialize(configuration = {})
        @config = configuration.dup

        setup if respond_to?(:setup)
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

      def changed?(_record, _attribute)
        raise NotImplementedError, "Implement changed? on #{self.class.name}"
      end

      def accept?(_resource)
        raise NotImplementedError, "Implement accept? on #{self.class.name}"
      end

      def asset_path(_asset)
        raise NotImplementedError, "Implement path on #{self.class.name}"
      end

      def asset_remove(_asset)
        raise NotImplementedError, "Implement remove on #{self.class.name}"
      end

      protected

      def processable(asset)
        Processable.new(self, asset)
      end
    end
  end
end
