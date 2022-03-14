# frozen_string_literal: true

module Ratonvirus
  module Scanner
    # Dummy EICAR file scanner to test the integration with this gem.
    #
    # Only to be used for testing the functionality of this gem.
    class Eicar < Base
      # SHA256 digest of the EICAR test file for virus testing
      # See: https://en.wikipedia.org/wiki/EICAR_test_file
      #
      # This includes both, the default hash and a hash with for the file saved
      # with a newline at the end of it.
      EICAR_SHA256 = %w(
        275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f
        131f95c51cc819465fa1797f6ccacf9d494aaaff46fa3eac73ae63ffbdfd8267
      ).freeze

      class << self
        def executable?
          true
        end
      end

      protected

      def run_scan(path)
        if File.file?(path)
          sha256 = Digest::SHA256.file path
          errors << :antivirus_virus_detected if EICAR_SHA256.include?(sha256.to_s)
        else
          errors << :antivirus_file_not_found
        end
      rescue StandardError
        errors << :antivirus_client_error
      end
    end
  end
end
