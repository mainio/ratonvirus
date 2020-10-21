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

        if asset.file.is_a?(CarrierWave::Storage::Fog::File)
          # We can't use carrierwave_uploader.cache_stored_file! as this is
          # remote too when using fog/s3.
          @tempfile = Tempfile.new(encoding: "ascii-8bit") do |f|
            f.write(asset.read)
          end

          yield @tempfile.path
        else
          yield asset.file.path
        end
      end

      def asset_remove(asset)
        if asset.file.is_a?(CarrierWave::Storage::Fog::File)
          @tempfile.close
        else
          path = asset.file.path
          asset.remove!

          # Remove the temp cache dir if it exists
          dir = File.dirname(path)
          FileUtils.remove_dir(dir) if File.directory?(dir)
        end
      end
    end
  end
end
