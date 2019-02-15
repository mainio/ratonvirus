# frozen_string_literal: true

require "spec_helper"

describe Ratonvirus do
  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) do
    # Define test addon
    test_addon = Module.new
    # Make the addon available as `Ratonvirus::Scanner::Addon::Test`
    described_class::Scanner::Addon.const_set(:Test, test_addon)

    # Define test scanner
    test_scanner = Class.new described_class::Scanner::Base
    # Make the scanner available as `Ratonvirus::Scanner::Test`
    described_class::Scanner.const_set(:Test, test_scanner)

    # Define test storage
    test_storage = Class.new described_class::Storage::Base
    # Make the scanner available as `Ratonvirus::Storage::Test`
    described_class::Storage.const_set(:Test, test_storage)
  end
  # rubocop:enable RSpec/BeforeAfterAll

  before do
    # Make sure the default configs are applied to all tests in this spec since
    # the default configuration is modified for the other tests.
    described_class.reset
  end

  it "has default addons" do
    expect(described_class.addons).to contain_exactly(
      described_class::Scanner::Addon::RemoveInfected
    )
  end

  it "is configurable" do
    expect { |b| described_class.configure(&b) }.to yield_with_args(
      described_class
    )
  end

  context "with addons" do
    it "accepts new addons to be configured" do
      described_class.configure do |config|
        config.add_addon :test
      end

      expect(described_class.addons).to include(
        described_class::Scanner::Addon::Test
      )
    end

    it "accepts removing addons through configuration" do
      described_class.configure do |config|
        config.remove_addon :remove_infected
      end

      expect(described_class.addons).to be_empty
    end

    it "accepts all addons to be configured" do
      described_class.configure do |config|
        config.addons = [:remove_infected, :test]
      end
      expect(described_class.addons).to contain_exactly(
        described_class::Scanner::Addon::RemoveInfected,
        described_class::Scanner::Addon::Test
      )

      described_class.configure do |config|
        config.addons = [:test]
      end
      expect(described_class.addons).to contain_exactly(
        described_class::Scanner::Addon::Test
      )

      described_class.configure do |config|
        config.addons = []
      end
      expect(described_class.addons).to be_empty
    end
  end

  context "with scanner" do
    it "returns configured scanner" do
      described_class.configure do |config|
        config.scanner = :test
      end

      expect(described_class.scanner).to be_a(described_class::Scanner::Test)
    end

    it "returns a scanner configured as a class" do
      scanner = described_class::Scanner::Test.new
      described_class.configure do |config|
        config.scanner = scanner
      end

      expect(described_class.scanner).to equal(scanner)
    end

    it "allows reconfiguring a scanner" do
      described_class.configure do |config|
        config.scanner = :eicar
      end
      # This creates a new scanner instance for the Eicar scanner
      described_class.scanner

      # Reconfiguring should destroy the previously configured scanner
      described_class.configure do |config|
        config.scanner = :test
      end

      # So when fetching the scanner again, it should be a Test scanner
      expect(described_class.scanner).to be_a(described_class::Scanner::Test)
    end

    it "stores the scanner instance" do
      described_class.configure do |config|
        config.scanner = :test
      end

      scanner = described_class.scanner
      expect(described_class.scanner).to equal(scanner)
    end

    it "allows destroying the scanner instance" do
      described_class.configure do |config|
        config.scanner = :test
      end

      scanner = described_class.scanner
      described_class.destroy_scanner
      expect(described_class.scanner).not_to equal(scanner)

      # Destroying a class defined scanner
      scanner = described_class::Scanner::Test.new
      described_class.configure do |config|
        config.scanner = scanner
      end

      described_class.destroy_scanner
      expect(described_class.scanner).not_to equal(scanner)
      expect(described_class.scanner).to be_a(described_class::Scanner::Test)
    end
  end

  context "with storage" do
    it "returns configured storage" do
      described_class.configure do |config|
        config.storage = :filepath
      end

      expect(described_class.storage).to be_a(
        described_class::Storage::Filepath
      )
    end

    it "returns a storage configured as a class" do
      storage = described_class::Storage::Test.new
      described_class.configure do |config|
        config.storage = storage
      end

      expect(described_class.storage).to equal(storage)
    end

    it "allows reconfiguring a storage" do
      described_class.configure do |config|
        config.storage = :filepath
      end
      # This creates a new storage instance for the File storage
      described_class.storage

      # Reconfiguring should destroy the previously configured storage
      described_class.configure do |config|
        config.storage = :test
      end

      # So when fetching the scanner again, it should be a Test storage
      expect(described_class.storage).to be_a(described_class::Storage::Test)
    end

    it "stores the storage instance" do
      described_class.configure do |config|
        config.storage = :test
      end

      storage = described_class.storage
      expect(described_class.storage).to equal(storage)
    end

    it "allows destroying the storage instance" do
      described_class.configure do |config|
        config.storage = :test
      end

      storage = described_class.storage
      described_class.destroy_storage
      expect(described_class.storage).not_to equal(storage)

      # Destroying a class defined storage
      storage = described_class::Storage::Test.new
      described_class.configure do |config|
        config.storage = storage
      end

      described_class.destroy_storage
      expect(described_class.storage).not_to equal(storage)
      expect(described_class.storage).to be_a(described_class::Storage::Test)
    end
  end
end
