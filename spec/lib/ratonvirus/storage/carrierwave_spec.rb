# frozen_string_literal: true

require "rails_helper"

describe Ratonvirus::Storage::Carrierwave do
  describe "#changed?" do
    let(:record) { double }
    let(:attribute) { :file }

    it "returns true when attribute is marked as dirty" do
      expect(record).to receive(:file_changed?).and_return(true)
      expect(subject.changed?(record, attribute)).to be(true)
    end

    it "returns false when attribute is not marked as dirty" do
      expect(record).to receive(:file_changed?).and_return(false)
      expect(subject.changed?(record, attribute)).to be(false)
    end
  end

  describe "#accept?" do
    let(:uploader) do
      Class.new CarrierWave::Uploader::Base
    end

    context "with CarrierWave::Uploader::Base" do
      it "is true" do
        expect(subject.accept?(uploader.new)).to be(true)
      end
    end

    context "with Array" do
      context "when empty" do
        it "is true" do
          expect(subject.accept?([])).to be(true)
        end
      end

      context "when containing only CarrierWave::Uploader::Base" do
        it "is true" do
          expect(
            subject.accept?([uploader.new, uploader.new, uploader.new])
          ).to be(true)
        end
      end

      context "when containing CarrierWave::Uploader::Base and something else" do
        it "is false" do
          expect(
            subject.accept?([uploader.new, double, uploader.new])
          ).to be(false)
        end
      end
    end
  end

  describe "#asset_path" do
    let(:asset) { double }
    let(:clean_file) { File.new(ratonvirus_file_fixture("clean_file.pdf"), "r") }

    context "when a block is not given" do
      it "does nothing" do
        expect(asset).not_to receive(:nil?)
        subject.asset_path(asset)
      end
    end

    context "when a block is given" do
      it "does not yield with nil asset" do
        expect { |b| subject.asset_path(nil, &b) }.not_to yield_control
      end

      it "does not yield with asset.file returning nil" do
        allow(asset).to receive(:file).and_return(nil)
        expect { |b| subject.asset_path(asset, &b) }.not_to yield_control
      end

      it "yields with with a temp path of the copy of the asset" do
        expect(asset).to receive(:file).exactly(4).times.and_return(clean_file)
        expect { |b| subject.asset_path(asset, &b) }.to yield_with_args(
          %r{/tmp/Ratonvirus[0-9]+-[0-9]+-[0-9a-z]+\.pdf}
        )
      end

      context "with Fog backend" do
        let(:record) { Article.new(carrierwave_file: clean_file) }
        let(:uploader) { record.carrierwave_file }
        let(:fog_file) do
          CarrierWave::Storage::Fog::File.new(
            uploader,
            uploader.class.storage.new(uploader),
            uploader.store_path
          )
        end

        before do
          # In order for Fog to read the file, we would have to configure and
          # stub a lot of stuff to emulate the cloud connection. To make things
          # easier, just stub the `#read` method for the file and return the
          # file contents.
          allow(fog_file).to receive(:read).and_return(clean_file.read)
        end

        it "yields with with a temp path of the copy of the asset" do
          expect(asset).to receive(:file).exactly(4).times.and_return(fog_file)
          expect { |b| subject.asset_path(asset, &b) }.to yield_with_args(
            %r{/tmp/Ratonvirus[0-9]+-[0-9]+-[0-9a-z]+\.pdf}
          )
        end
      end
    end
  end

  describe "#asset_remove" do
    let(:asset) { double }
    let(:file) { double }
    let(:path) { double }
    let(:dir) { double }

    before do
      expect(asset).to receive(:file).and_return(file)
      expect(file).to receive(:path).and_return(path)
      expect(asset).to receive(:remove!)
      expect(File).to receive(:dirname).with(path).and_return(dir)
    end

    context "with correct folder" do
      it "calls asset.remove! and removes its folder" do
        expect(File).to receive(:directory?).with(dir).and_return(true)
        expect(FileUtils).to receive(:remove_dir).with(dir)

        subject.asset_remove(asset)
      end
    end

    context "with incorrect folder" do
      it "calls asset.remove! and does not remove its folder" do
        expect(File).to receive(:directory?).with(dir).and_return(false)
        expect(FileUtils).not_to receive(:remove_dir)

        subject.asset_remove(asset)
      end
    end
  end
end
