# frozen_string_literal: true

module Ratonvirus
  module Scanner
    # Dummy EICAR file scanner to test the integration with this gem.
    #
    # Only to be used for testing the functionality of this gem.
    class Eicar < Base
      # SHA256 digest of the EICAR test file for virus testing
      # See: https://en.wikipedia.org/wiki/EICAR_test_file
      EICAR_SHA256 = "131f95c51cc819465fa1797f6ccacf9d494aaaff46fa3eac73ae63ffbdfd8267"

      class << self
        def executable?
          true
        end
      end

      protected

      def run_scan(path)
        if File.file?(path)
          sha256 = Digest::SHA256.file path
          errors << :antivirus_virus_detected if sha256 == EICAR_SHA256
        else
          errors << :antivirus_file_not_found
        end
      rescue StandardError
        errors << :antivirus_client_error
      end
    end
  end
end
