# frozen_string_literal: true

module Ratonvirus
  module Storage
    class ActiveStorage < Base
      def changed?(_record, _attribute)
        # With Active Storage we assume the record is always changed because
        # there is currently no way to know if the attribute has actually
        # changed.
        #
        # Calling record.changed? will not also work because it is not marked
        # as dirty in case the Active Storage attachment has changed.
        #
        # NOTE:
        # This should be changed in the future as the `attachment_changes` was
        # introduced to Rails by this commit:
        # https://github.com/rails/rails/commit/e8682c5bf051517b0b265e446aa1a7eccfd47bf7
        #
        # However, it is still not available in Rails 5.2.x.
        true
      end

      def accept?(resource)
        resource.is_a?(::ActiveStorage::Attached::One) ||
          resource.is_a?(::ActiveStorage::Attached::Many)
      end

      def process(resource, &_block)
        return unless block_given?
        return if resource.nil?

        return unless resource.attached?

        if resource.is_a?(::ActiveStorage::Attached::One)
          yield processable(resource.attachment) if resource.attachment
        elsif resource.is_a?(::ActiveStorage::Attached::Many)
          resource.attachments.each do |attachment|
            yield processable(attachment)
          end
        end
      end

      def asset_path(asset, &block)
        return unless block_given?
        return if asset.nil?
        return unless asset.blob

        blob_path asset.blob, &block
      end

      def asset_remove(asset)
        asset.purge
      end

      private

      # This creates a local copy of the blob for the scanning process. A
      # local copy is needed for processing because the actual blob may be
      # stored at a remote storage service (such as Amazon S3), meaning it
      # cannot be otherwise processed locally.
      #
      # NOTE:
      # Later implementations of Active Storage have the blob.open method that
      # provides similar functionality. However, Rails 5.2.x still does not
      # include this functionality, so we need to take care of it ourselves.
      #
      # This was introduced in the following commit:
      # https://github.com/rails/rails/commit/ee21b7c2eb64def8f00887a9fafbd77b85f464f1
      #
      # SEE:
      # https://edgeguides.rubyonrails.org/active_storage_overview.html#downloading-files
      def blob_path(blob)
        tempfile = Tempfile.open(
          ["Ratonvirus", blob.filename.extension_with_delimiter],
          tempdir
        )

        begin
          tempfile.binmode
          blob.download { |chunk| tempfile.write(chunk) }
          tempfile.flush
          tempfile.rewind

          yield tempfile.path
        rescue StandardError
            return
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
