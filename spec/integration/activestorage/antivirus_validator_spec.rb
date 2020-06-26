# frozen_string_literal: true

require "rails_helper"

describe AntivirusValidator do
  let(:clean_file) { fixture_file_upload("files/clean_file.pdf") }
  let(:clean_file_io) { File.open(file_fixture("clean_file.pdf")) }
  let(:infected_file) { fixture_file_upload("files/infected_file.pdf") }
  let(:infected_file_io) { File.open(file_fixture("infected_file.pdf")) }

  before do
    Ratonvirus.configure do |config|
      config.scanner = :eicar
      config.storage = :active_storage
    end
  end

  context "with single file" do
    let(:article) do
      a = Article.new
      a.activestorage_file.attach(attachment)
      a
    end

    context "when the file is clean" do
      let(:attachment) { clean_file }

      it "is valid" do
        expect(article).to be_valid
      end

      context "and the file is provided as io" do
        let(:attachment) { { io: clean_file_io, filename: "clean_file.pdf" } }

        it "is valid" do
          expect(article).to be_valid
        end
      end
    end

    context "when the file is infected" do
      let(:attachment) { infected_file }

      it "is not valid" do
        expect(article).not_to be_valid
      end

      context "and the file is provided as io" do
        let(:attachment) { { io: infected_file_io, filename: "infected_file.pdf" } }

        it "is not valid" do
          expect(article).not_to be_valid
        end
      end
    end
  end

  context "with multiple files" do
    let(:article) do
      a = Article.new
      5.times do
        a.activestorage_files.attach(attachment)
      end
      a
    end

    context "when the files are clean" do
      let(:attachment) { clean_file }

      it "is valid" do
        expect(article).to be_valid
      end

      context "and the files are provided as io" do
        let(:attachment) { { io: clean_file_io, filename: "clean_file.pdf" } }

        it "is valid" do
          expect(article).to be_valid
        end
      end
    end

    context "when the files are infected" do
      let(:attachment) { infected_file }

      it "is not valid" do
        expect(article).not_to be_valid
      end

      context "and the files are provided as io" do
        let(:attachment) { { io: infected_file_io, filename: "infected_file.pdf" } }

        it "is not valid" do
          expect(article).not_to be_valid
        end
      end
    end

    context "when containing a single infected file" do
      let(:clean_attachment) { clean_file }
      let(:infected_attachment) { infected_file }

      let(:article) do
        a = Article.new
        5.times do
          a.activestorage_files.attach(clean_attachment)
        end
        a.activestorage_files.attach(infected_attachment)
        a
      end

      it "is not valid" do
        expect(article).not_to be_valid
      end

      context "and the files are provided as io" do
        let(:clean_attachment) { { io: clean_file_io, filename: "clean_file.pdf" } }
        let(:infected_attachment) { { io: infected_file_io, filename: "infected_file.pdf" } }

        it "is not valid" do
          expect(article).not_to be_valid
        end
      end
    end

    context "when containing multiple clean and multiple infected files" do
      let(:clean_attachment) { clean_file }
      let(:infected_attachment) { infected_file }

      let(:article) do
        a = Article.new
        5.times do
          a.activestorage_files.attach(clean_attachment)
        end
        5.times do
          a.activestorage_files.attach(infected_attachment)
        end
        a
      end

      it "is not valid" do
        expect(article).not_to be_valid
      end

      context "and the files are provided as io" do
        let(:clean_attachment) { { io: clean_file_io, filename: "clean_file.pdf" } }
        let(:infected_attachment) { { io: infected_file_io, filename: "infected_file.pdf" } }

        it "is not valid" do
          expect(article).not_to be_valid
        end
      end
    end
  end
end
