# frozen_string_literal: true

module Ratonvirus
  module Test
    module Helpers
      def spec_path
        File.expand_path(__dir__)
      end

      def ratonvirus_file_fixture(filepath)
        "#{spec_path}/fixtures/files/#{filepath}"
      end

      def activestorage_digest(io)
        # This is how ActiveStorage would calculate the digest.
        #
        # See:
        # https://github.com/rails/rails/blob/afd103d69abb7441da3d2ac5c737f8de3e678779/activestorage/lib/active_storage/service.rb#L161-L168
        OpenSSL::Digest::MD5.new.tap do |checksum|
          read_buffer = "".b
          io.read(nil, read_buffer)
          checksum << read_buffer
          io.rewind
        end.base64digest
      end
    end
  end
end
