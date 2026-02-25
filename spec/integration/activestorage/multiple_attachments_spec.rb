# frozen_string_literal: true

require "rails_helper"

describe "Scanning behavior for single and multiple attachments" do
  let(:clean_file_1) { Rack::Test::UploadedFile.new(ratonvirus_file_fixture("clean_file.pdf"), "application/pdf") }
  let(:clean_file_2) { Rack::Test::UploadedFile.new(ratonvirus_file_fixture("clean_file.pdf"), "application/pdf") }
  let(:clean_file_3) { Rack::Test::UploadedFile.new(ratonvirus_file_fixture("clean_file.pdf"), "application/pdf") }
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
      article = Article.new
      article.activestorage_file.attach(clean_file_1)

      expect(article).to be_valid
    end

    it "does not re-scan already scanned blob" do
      article = Article.new
      article.activestorage_file.attach(infected_file)
      article.save(validate: false)

      existing_blob = article.activestorage_file.blob
      article.activestorage_file.attach(existing_blob)

      expect(article).to be_valid
    end

    it "scans newly created blob that has not been validated yet" do
      article = Article.new
      article.activestorage_file.attach(infected_file_blob)

      expect(article).not_to be_valid
    end
  end

  context "when attaching multiple files" do
    it "scans all files" do
      article = Article.new
      article.activestorage_files.attach([clean_file_1, clean_file_2, clean_file_3])

      expect(article).to be_valid
    end

    it "does not re-scan when no files change" do
      article = Article.create!
      article.activestorage_files.attach([infected_file, clean_file_2])
      article.save(validate: false)

      blob_a = article.activestorage_files[0].blob
      blob_b = article.activestorage_files[1].blob
      article.activestorage_files.attach([blob_a, blob_b])

      expect(article).to be_valid
    end

    it "scans only new files when added to existing files" do
      article = Article.create!
      article.activestorage_files.attach([infected_file, clean_file_2])
      article.save(validate: false)

      blob_a = article.activestorage_files[0].blob
      blob_b = article.activestorage_files[1].blob
      article.activestorage_files = [blob_a, blob_b, clean_file_3]

      expect(article).to be_valid
    end
  end
end
