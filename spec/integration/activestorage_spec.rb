# frozen_string_literal: true

require "rails_helper"

describe AntivirusValidator do
  let(:clean_file) { fixture_file_upload('files/clean_file.pdf') }
  let(:infected_file) { fixture_file_upload('files/infected_file.pdf') }

  before(:each) do
    Ratonvirus.configure do |config|
      config.scanner = :eicar
      config.storage = :active_storage
    end
  end

  context 'with single clean file' do
    it 'should be valid' do
      a = Article.new
      a.activestorage_file.attach(clean_file)

      expect(a).to be_valid
    end
  end

  context 'with single infected file' do
    it 'should be not valid' do
      a = Article.new
      a.activestorage_file.attach(infected_file)

      expect(a).not_to be_valid
    end
  end

  context 'with multiple clean files' do
    it 'should be valid' do
      a = Article.new
      10.times do
        a.activestorage_files.attach(clean_file)
      end

      expect(a).to be_valid
    end
  end

  context 'with multiple infected files' do
    it 'should be not valid' do
      a = Article.new
      10.times do
        a.activestorage_files.attach(infected_file)
      end

      expect(a).not_to be_valid
    end
  end

  context 'with multiple files containing single infected file' do
    it 'should be not valid' do
      a = Article.new
      10.times do
        a.activestorage_files.attach(clean_file)
      end
      a.activestorage_files.attach(infected_file)

      expect(a).not_to be_valid
    end
  end

  context 'with multiple files containing multiple infected files' do
    it 'should be not valid' do
      a = Article.new
      10.times do
        a.activestorage_files.attach(clean_file)
      end
      10.times do
        a.activestorage_files.attach(infected_file)
      end

      expect(a).not_to be_valid
    end
  end
end
