# frozen_string_literal: true

require "spec_helper"

describe Ratonvirus::Storage::Filepath do
  describe "#changed?" do
    let(:record) { double }

    context 'when record responds to attribute_changed?' do
      before(:each) do
        expect(record).to receive(:respond_to?).with(:x_changed?)
          .and_return(true).ordered
      end

      context 'and attribute has changed' do
        it 'returns expected result' do
          expect(record).to receive(:x_changed?).and_return(true)
          expect(record).not_to receive(:changed?)

          expect(subject.changed?(record, :x)).to be(true)
        end
      end

      context 'and attribute has not changed' do
        it 'returns expected result' do
          expect(record).to receive(:x_changed?).and_return(false)
          expect(record).not_to receive(:changed?)

          expect(subject.changed?(record, :x)).to be(false)
        end
      end
    end

    context 'when record does not respond to x_changed?' do
      before(:each) do
        expect(record).to receive(:respond_to?).with(:x_changed?)
          .and_return(false).ordered
        expect(record).not_to receive(:x_changed?)
      end

      context 'and record has changed' do
        it 'returns expected result' do
          expect(record).to receive(:changed?).and_return(true).ordered
          expect(subject.changed?(record, :x)).to be(true)
        end
      end

      context 'and record has not changed' do
        it 'returns expected result' do
          expect(record).to receive(:changed?).and_return(false).ordered
          expect(subject.changed?(record, :x)).to be(false)
        end
      end
    end
  end

  describe "#accept?" do
    context 'when the resource is a String' do
      it 'returns true' do
        expect(subject.accept?('string')).to be(true)
      end
    end

    context 'when the resource is a File' do
      it 'returns true' do
        file = File.new(ratonvirus_file_fixture('clean_file.pdf'))
        expect(subject.accept?(file)).to be(true)
      end
    end

    context 'when the resource is an Array' do
      context 'containing Strings' do
        it 'returns true' do
          expect(subject.accept?(['string', 'string', 'string'])).to be(true)
        end
      end

      context 'containing Files' do
        let(:path) { ratonvirus_file_fixture('clean_file.pdf') }

        it 'returns true' do
          expect(subject.accept?(
            [File.new(path), File.new(path), File.new(path)]
          )).to be(true)
        end
      end

      context 'something else' do
        it 'returns false' do
          expect(subject.accept?([double, double, double])).to be(false)
        end
      end

      context 'containing Strings and Files' do
        let(:path) { ratonvirus_file_fixture('clean_file.pdf') }

        it 'returns true' do
          expect(subject.accept?(
            [File.new(path), File.new(path), File.new(path)] +
            ['string', 'string', 'string']
          )).to be(true)
        end
      end

      context 'containing Strings, Files and something else' do
        let(:path) { ratonvirus_file_fixture('clean_file.pdf') }

        it 'returns false' do
          expect(subject.accept?(
            [File.new(path), File.new(path), File.new(path)] +
            ['string', 'string', 'string'] +
            [double, double, double]
          )).to be(false)
        end
      end
    end

    context 'when the resource is something else' do
      it 'returns false' do
        expect(subject.accept?(double)).to be(false)
      end
    end
  end

  describe "#asset_path" do
    let(:asset) { double }

    context 'when block is not given' do
      let(:path) { ratonvirus_file_fixture('clean_file.pdf') }

      it 'should not asset.empty?' do
        expect(asset).not_to receive(:empty?)

        subject.asset_path(nil)
        subject.asset_path('test')
        subject.asset_path(File.file?(path))
      end
    end

    context 'when block is given' do
      context 'with nil asset' do
        it 'should not call asset.empty?' do
          expect(asset).not_to receive(:empty?)
          expect{ |b| subject.asset_path(nil, &b) }.not_to yield_control
        end
      end

      context 'with asset responding true to .empty?' do
        before(:each) do
          expect(asset).to receive(:empty?).and_return(true)
        end

        it 'should not call asset.respond_to?' do
          expect(asset).not_to receive(:respond_to?)
          expect{ |b| subject.asset_path(asset, &b) }.not_to yield_control
        end
      end

      context 'with asset responding false to .empty?' do
        before(:each) do
          expect(asset).to receive(:empty?).and_return(false)
        end

        context 'and asset not responding to .path' do
          it 'should yield the asset itself' do
            expect{ |b| subject.asset_path(asset, &b) }.to(
              yield_with_args(asset)
            )
          end
        end

        context 'and asset responding to .path' do
          let(:path) { double }

          it 'should yield with the response of asset.path' do
            # Call to asset.path
            expect(asset).to receive(:path).and_return(path)
            expect(path).to receive(:empty?).and_return(false)

            expect{ |b| subject.asset_path(asset, &b) }.to(
              yield_with_args(path)
            )
          end
        end
      end
    end
  end

  describe "#asset_remove" do
    let(:asset) { double }

    it 'should not remove the asset when it is not a file' do
      expect(File).to receive(:file?).and_return(false)
      expect(FileUtils).not_to receive(:remove_file)
      subject.asset_remove(asset)
    end

    it 'should remove the asset when it is a file' do
      expect(File).to receive(:file?).and_return(true)
      expect(FileUtils).to receive(:remove_file).with(asset)
      subject.asset_remove(asset)
    end
  end
end
