# frozen_string_literal: true

module Ratonvirus
  module Storage
    class Carrierwave < Base
      include Ratonvirus::Storage::Support::IoHandling

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

      def asset_path(asset, &block)
        return unless block_given?
        return if asset.nil?
        return if asset.file.nil?

        # If the file is a local SanitizedFile, it is faster to run the scan
        # directly against that file instead of copying it to a tempfile first
        # as below for external file storages.
        return yield asset.file.path if asset.file.is_a?(::CarrierWave::SanitizedFile)

        # The file could be externally stored, so we need to read it to memory
        # in order to create a temporary file for the scanner to perform the
        # scan on.
        io = StringIO.new(asset.file.read)
        ext = File.extname(asset.file.path)
        io_path(io, ext, &block)
      end

      def asset_remove(asset)
        path = asset.file.path
        delete_dir = asset.file.is_a?(::CarrierWave::SanitizedFile)
        asset.remove!

        return unless delete_dir

        # Remove the temp cache dir if it exists
        dir = File.dirname(path)
        FileUtils.remove_dir(dir) if File.directory?(dir)
      end
    end
  end
end
