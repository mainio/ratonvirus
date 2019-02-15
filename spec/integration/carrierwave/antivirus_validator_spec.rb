# frozen_string_literal: true

require "rails_helper"

describe AntivirusValidator do
  let(:clean_file) { fixture_file_upload("files/clean_file.pdf") }
  let(:infected_file) { fixture_file_upload("files/infected_file.pdf") }

  before do
    Ratonvirus.configure do |config|
      config.scanner = :eicar
      config.storage = :carrierwave
    end
  end

  context "with single clean file" do
    it "is valid" do
      a = Article.new
      a.carrierwave_file = clean_file

      expect(a).to be_valid
    end
  end

  context "with single infected file" do
    it "is not valid" do
      a = Article.new
      a.carrierwave_file = infected_file

      expect(a).not_to be_valid
    end
  end

  context "with multiple clean files" do
    it "is valid" do
      a = Article.new

      files = []
      10.times do
        files << clean_file
      end
      a.carrierwave_files = files

      expect(a).to be_valid
    end
  end

  context "with multiple infected files" do
    it "is not valid" do
      a = Article.new

      files = []
      10.times do
        files << infected_file
      end
      a.carrierwave_files = files

      expect(a).not_to be_valid
    end
  end

  context "with multiple files containing single infected file" do
    it "is not valid" do
      a = Article.new

      files = []
      10.times do
        files << clean_file
      end
      files << infected_file
      a.carrierwave_files = files

      expect(a).not_to be_valid
    end
  end

  context "with multiple files containing multiple infected files" do
    it "is not valid" do
      a = Article.new

      files = []
      10.times do
        files << clean_file
      end
      10.times do
        files << infected_file
      end
      a.carrierwave_files = files

      expect(a).not_to be_valid
    end
  end
end
