module Ratonvirus
  module Test
    module Helpers
      def spec_path
        File.expand_path(File.dirname(__FILE__))
      end

      def ratonvirus_file_fixture(filepath)
        "#{spec_path}/fixtures/files/#{filepath}"
      end
    end
  end
end
