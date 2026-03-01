# frozen_string_literal: true

require "rails_helper"


describe "Scanning behavior for single and multiple attachments" do
  let(:clean_file1) { Rack::Test::UploadedFile.new(ratonvirus_file_fixture("clean_file.pdf"), "application/pdf") }
  let(:clean_file2) { Rack::Test::UploadedFile.new(ratonvirus_file_fixture("clean_file.pdf"), "application/pdf") }
  let(:clean_file3) { Rack::Test::UploadedFile.new(ratonvirus_file_fixture("clean_file.pdf"), "application/pdf") }
  let(:infected_file) { Rack::Test::UploadedFile.new(ratonvirus_file_fixture("infected_file.pdf"), "application/pdf") }
  let(:infected_file_blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(ratonvirus_file_fixture("infected_file.pdf")),
      filename: "infected_file.pdf"
    )
  end

  before do
    Ratonvirus.configure do |config|
      config.scanner = :eicar
      config.storage = :active_storage
    end
  end

  context "when attaqching a single file" do
    it "scans new file" do
      scanner = Ratonvirus.scanner
      expect(scanner).to receive(:run_scan).once.and_call_original

      article = Article.new
      article.activestorage_file.attach(clean_file1)

      expect(article).to be_valid
    end

    # attaching an eicar file that would normally raise a validation error
    # means that file isnt being scanned once already attached
    it "does not re-scan already scanned blob" do
      article = Article.new
      article.activestorage_file.attach(infected_file)
      article.save(validate: false)

      scanner = Ratonvirus.scanner
      expect(scanner).not_to receive(:run_scan)

      existing_blob = article.activestorage_file.blob
      article.activestorage_file.attach(existing_blob)

      expect(article).to be_valid
    end

    it "scans newly created blob that has not been validated yet" do
      scanner = Ratonvirus.scanner
      expect(scanner).to receive(:run_scan).once.and_call_original

      article = Article.new
      article.activestorage_file.attach(infected_file_blob)

      expect(article).not_to be_valid
    end
  end

  context "when attaching multiple files" do
    it "scans all files" do
      scanner = Ratonvirus.scanner
      expect(scanner).to receive(:run_scan).exactly(3).times.and_call_original

      article = Article.new
      article.activestorage_files.attach([clean_file1, clean_file2, clean_file3])

      expect(article).to be_valid
    end

    # attaching an eicar file that would normally raise a validation error
    # means that file isnt being scanned once already attached
    it "does not re-scan when no files change" do
      article = Article.create!
      article.activestorage_files.attach([infected_file, clean_file2])
      article.save(validate: false)

      scanner = Ratonvirus.scanner
      expect(scanner).not_to receive(:run_scan)

      blob_a = article.activestorage_files[0].blob
      blob_b = article.activestorage_files[1].blob
      article.activestorage_files.attach([blob_a, blob_b])

      expect(article).to be_valid
    end

    # attaching an eicar file that would normally raise a validation error
    # means that file isnt being scanned once already attached
    it "scans only new files when added to existing files" do
      article = Article.create!
      article.activestorage_files.attach([infected_file, clean_file2])
      article.save(validate: false)

      scanner = Ratonvirus.scanner
      expect(scanner).to receive(:run_scan).once.and_call_original

      blob_a = article.activestorage_files[0].blob
      blob_b = article.activestorage_files[1].blob
      article.activestorage_files = [blob_a, blob_b, clean_file3]

      expect(article).to be_valid
    end
  end
end
