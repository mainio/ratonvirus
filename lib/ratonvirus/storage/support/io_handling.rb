# frozen_string_literal: true

require "tempfile"

module Ratonvirus
  module Storage
    module Support
      module IoHandling
        private

        # This creates a local copy of the io contents for the scanning process.
        # A local copy is needed for processing because the io object may be a
        # file stream in the memory which may not have a path associated with it
        # on the filesystem.
        def io_path(io, extension)
          tempfile = Tempfile.open(
            ["Ratonvirus", extension],
            tempdir
          )
          # Important for the scanner to be able to access the file.
          prepare_for_scanner tempfile.path

          begin
            tempfile.binmode
            IO.copy_stream(io, tempfile, nil, 0)
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
end
