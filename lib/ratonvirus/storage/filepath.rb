module Ratonvirus
  module Storage
    class Filepath < Base
      def changed?(record, attribute)
        if record.respond_to? :"#{attribute}_changed?"
          return record.public_send :"#{attribute}_changed?"
        end

        # Some backends do not implement the `attribute_changed?` methods for
        # the file resources. In that case our best guess is to check whether
        # the whole record has changed.
        record.changed?
      end

      def accept?(resource)
        if resource.is_a?(Array)
          resource.all? { |r| r.is_a?(String) || r.is_a?(File) }
        else
          resource.is_a?(String) || resource.is_a?(File)
        end
      end

      def asset_path(asset, &block)
        return unless block_given?

        return unless asset
        return if asset.empty?

        if asset.respond_to?(:path)
          # A file asset that responds to path (e.g. default `File`
          # object).
          asset_path(asset.path, &block)

          return
        end

        # Plain file path string provided as resource
        yield asset
      end

      def asset_remove(asset)
        FileUtils.remove_file(asset) if File.file?(asset)
      end
    end
  end
end
