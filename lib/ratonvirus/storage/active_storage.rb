# frozen_string_literal: true

module Ratonvirus
  module Storage
    class ActiveStorage < Base
      def changed?(record, attribute)
        resource = record.public_send attribute
        !resource.record.attachment_changes[resource.name].nil?
      end

      def accept?(resource)
        resource.is_a?(::ActiveStorage::Attached::One) ||
          resource.is_a?(::ActiveStorage::Attached::Many)
      end

      def process(resource, &block)
        return unless block_given?
        return if resource.nil?
        return unless resource.attached?

        change = resource.record.attachment_changes[resource.name]

        if change.is_a?(::ActiveStorage::Attached::Changes::CreateOne)
          handle_create_one(change, &block)
        elsif change.is_a?(::ActiveStorage::Attached::Changes::CreateMany)
          handle_create_many(change, &block)
        end
      end

      def asset_path(asset, &block)
        return unless block_given?
        return unless asset.is_a?(Array)

        case asset[1]
        when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile
          yield asset[1].path
        when Hash
          io = asset[1].fetch(:io)
          ext = asset[0].filename.extension_with_delimiter

          io_path(io, ext, &block) if io
        end
      end

      def asset_remove(asset)
        return unless asset.is_a?(Array)

        asset[0].purge
      end

      private

      def handle_create_one(change, &_block)
        return unless change.attachable

        yield processable(
          [change.attachment, change.attachable]
        )
      end

      def handle_create_many(change, &_block)
        change.send(:subchanges).each do |subchange|
          next unless subchange.attachable
          next if subchange.attachable.is_a?(::ActiveStorage::Blob)

          yield processable(
            [subchange.attachment, subchange.attachable]
          )
        end
      end

      # This creates a local copy of the io contents for the scanning process. A
      # local copy is needed for processing because the io object may be a file
      # stream in the memory which may not have a path associated with it on the
      # filesystem.
      def io_path(io, extension)
        tempfile = Tempfile.open(
          ["Ratonvirus", extension],
          tempdir
        )

        begin
          tempfile.binmode
          IO.copy_stream(io, tempfile)
          tempfile.flush
          tempfile.rewind

          yield tempfile.path
        ensure
          tempfile.close!
        end
      end

      def tempdir
        Dir.tmpdir
      end
    end
  end
end
