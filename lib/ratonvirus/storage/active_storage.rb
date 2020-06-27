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

        ext = asset[0].filename.extension_with_delimiter
        case asset[1]
        when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile
          # These files should be already locally stored but their permissions
          # can prevent the virus scanner executable from accessing them.
          # Therefore, a temporary file is created for them as well.
          io_path(asset[1], ext, &block)
        when Hash
          io = asset[1].fetch(:io)
          io_path(io, ext, &block) if io
        when ::ActiveStorage::Blob
          asset[1].open do |tempfile|
            prepare_for_scanner tempfile.path
            yield tempfile.path
          end
        end
      end

      # This is actually only required for the dyncamic blob uploads but for
      # consistency, it is handled for all the cases accordingly either by
      # closing the tempfile of the upload which also removes the file when
      # called with the bang method. For the IO references, the IO is closed
      # which should trigger the file deletion by latest at the Rack or Ruby
      # level during garbage collection. There is no guarantee that the file
      # for which the IO was opened would be deleted beause the IO itself is
      # not necessarily associated with an actual file.
      def asset_remove(asset)
        return unless asset.is_a?(Array)

        case asset[1]
        when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile
          # This removes the temp file from the system.
          asset[1].tempfile.close!
        when Hash
          # No guarantee all references for the file are deleted.
          io = asset[1].fetch(:io)
          io.close
        when ::ActiveStorage::Blob
          # This deletes the dynamically uploaded blobs that might not be
          # associated with any record at this point. This ensures the blobs are
          # not left "hanging" in the storage system and the database in case
          # automatic file deletion is applied.
          asset[1].purge
        end
      end

      private

      def handle_create_one(change, &block)
        yield_processable_from(change, &block)
      end

      def handle_create_many(change, &block)
        change.send(:subchanges).each do |subchange|
          yield_processable_from(subchange, &block)
        end
      end

      def yield_processable_from(change, &_block)
        attachable = change.attachable
        return unless attachable
        return if attachable.is_a?(::ActiveStorage::Blob)

        # If the attachable is a string, it is a reference to an already
        # existing blob. This can happen e.g. when the file blob is uploaded
        # dynamically before the form is submitted.
        attachable = change.attachment.blob if attachable.is_a?(String)

        yield processable([change.attachment, attachable])
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
        # Important for the scanner to be able to access the file.
        prepare_for_scanner tempfile.path

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

      def prepare_for_scanner(filepath)
        # Important for the scanner to be able to access the file.
        File.chmod(0o644, filepath)
      end
    end
  end
end
