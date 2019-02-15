# frozen_string_literal: true

namespace :ratonvirus do
  desc "Tests if the antivirus scanner is available and properly configured"
  task test: :environment do
    begin
      if Ratonvirus.scanner.available?
        puts "Ratonvirus correctly configured."
      else
        puts "Ratonvirus scanner is not available!"
        puts ""
        puts "Please refer to Ratonvirus documentation for proper configuration."
      end
    rescue StandardError
      puts "Ratonvirus scanner is not configured."
      puts ""
      puts "Please refer to Ratonvirus documentation for proper configuration."
    end
  end

  desc "Scans the given file through the antivirus scanner"
  task scan: :environment do |t, args|
    if args.extras.empty?
      puts "No files given."
      puts "Usage:"
      puts "  #{t.name}[/path/to/first/file.pdf,/path/to/second/file.pdf]"
      next
    end

    args.extras.each do |path|
      if File.file?(path)
        if Ratonvirus.scanner.virus?(path)
          puts "Detected a virus at: #{path}"
        else
          puts "Clean file at: #{path}"
        end
      else
        puts "File does not exist at: #{path}"
      end
    end
  end
end
