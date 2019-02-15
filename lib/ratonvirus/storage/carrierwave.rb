# frozen_string_literal: true

module Ratonvirus
  module Storage
    class Carrierwave < Base
      def changed?(record, attribute)
        record.public_send :"#{attribute}_changed?"
      end

      def accept?(resource)
        if resource.is_a?(Array)
          resource.all? { |subr| subr.is_a?(::CarrierWave::Uploader::Base) }
        else
          resource.is_a?(::CarrierWave::Uploader::Base)
        end
      end

      def asset_path(asset)
        return unless block_given?
        return if asset.nil?
        return if asset.file.nil?

        yield asset.file.path
      end

      def asset_remove(asset)
        path = asset.file.path
        asset.remove!

        # Remove the temp cache dir if it exists
        dir = File.dirname(path)
        FileUtils.remove_dir(dir) if File.directory?(dir)
      end
    end
  end
end
