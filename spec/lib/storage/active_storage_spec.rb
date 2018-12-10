# frozen_string_literal: true

require "spec_helper_rails"

describe Ratonvirus::Storage::ActiveStorage do
  describe '#changed?' do
    let(:record) { double }

    it 'should return true when record is changed' do
      allow(record).to receive(:changed?).and_return(true)
      expect(subject.changed?(record, :file)).to be(true)
    end

    it 'should return true when record is not changed' do
      allow(record).to receive(:changed?).and_return(false)
      expect(subject.changed?(record, :file)).to be(true)
    end

    it 'should return true when the attribute has changed' do
      allow(record).to receive(:file_changed?).and_return(true)
      expect(subject.changed?(record, :file)).to be(true)
    end

    it 'should return true when the attribute has not changed' do
      allow(record).to receive(:file_changed?).and_return(false)
      expect(subject.changed?(record, :file)).to be(true)
    end
  end

  describe '#accept?' do
    let(:resource) { double }

    it 'should return true with ActiveStorage::Attached::One' do
      expect(resource).to receive(:is_a?).with(ActiveStorage::Attached::One)
        .and_return(true)

      expect(subject.accept?(resource)).to be(true)
    end

    it 'should return true with ActiveStorage::Attached::Many' do
      expect(resource).to receive(:is_a?).with(ActiveStorage::Attached::One)
        .and_return(false)
      expect(resource).to receive(:is_a?).with(ActiveStorage::Attached::Many)
        .and_return(true)

      expect(subject.accept?(resource)).to be(true)
    end
  end

  describe '#process' do
    context 'with no block given' do
      let(:resource) { double }

      it 'should return without doing anything' do
        expect(resource).not_to receive(:nil?)
        subject.process(resource)
      end
    end

    context 'when resource is attached' do
      let(:processable) { double }
      let(:resource) { double }

      before(:each) do
        expect(resource).to receive(:attached?).and_return(true)
      end

      context 'with ActiveStorage::Attached::One' do
        let(:attachment) { double }

        before(:each) do
          expect(resource).to receive(:is_a?)
            .with(ActiveStorage::Attached::One).and_return(true)
        end

        it 'does nothing without an attachment' do
          expect(resource).to receive(:attachment).and_return(nil)
          expect(subject).not_to receive(:processable)
          subject.process(resource, &Proc.new {})
        end

        it 'calls processable and yields the result with attachment' do
          expect(resource).to receive(:attachment).twice
            .and_return(attachment)
          expect(subject).to receive(:processable).with(attachment)
            .and_return(processable)

          expect{ |b| subject.process(resource, &b) }.to yield_with_args(
            processable
          )
        end
      end

      context 'with ActiveStorage::Attached::Many' do
        before(:each) do
          expect(resource).to receive(:is_a?)
            .with(ActiveStorage::Attached::One).and_return(false)
          expect(resource).to receive(:is_a?)
            .with(ActiveStorage::Attached::Many).and_return(true)
        end

        it 'calls processable for all attachments and yields the correct results' do
          attachments = []
          processables = []

          10.times do
            attachment = double
            processable = double
            expect(subject).to receive(:processable).with(attachment)
              .and_return(processable)

            attachments << attachment
            processables << processable
          end

          expect(resource).to receive(:attachments).and_return(attachments)

          expect{ |b| subject.process(resource, &b) }.to yield_successive_args(
            *processables
          )
        end
      end
    end
  end

  describe '#asset_path' do
    let(:asset) { double }

    context 'when block is not provided' do
      it 'should not do anything' do
        expect(asset).not_to receive(:nil?)
        subject.asset_path(asset)
      end
    end

    context 'when block is provided' do
      let(:block) { Proc.new {} }

      context 'with nil asset' do
        it 'should not call asset.blob' do
          expect(asset).to receive(:nil?).and_return(true)
          expect(asset).not_to receive(:blob)
          subject.asset_path(asset, &block)
        end
      end

      context 'with no blob' do
        it 'should not call blob_path' do
          expect(asset).to receive(:nil?).and_return(false)
          expect(asset).to receive(:blob).and_return(nil)
          expect(subject).not_to receive(:blob_path)
          subject.asset_path(asset, &block)
        end
      end

      context 'with blob' do
        it 'should call blob_path' do
          blob = double
          expect(asset).to receive(:nil?).and_return(false)
          expect(asset).to receive(:blob).and_return(blob).twice
          expect(subject).to receive(:blob_path).with(blob, &block)
          subject.asset_path(asset, &block)
        end
      end
    end
  end

  describe '#asset_remove' do
    let(:asset) { double }

    it 'should call asset.purge' do
      expect(asset).to receive(:purge)
      subject.asset_remove(asset)
    end
  end

  describe '#blob_path' do
    let(:method) { subject.method(:blob_path) }
    let(:blob) { double }
    let(:tempfile) { double }
    before(:each) do
      filename = double

      # Define the expected methods implemented by ActiveStorage::Blob
      allow(blob).to receive(:filename).and_return(filename)
      allow(filename).to receive(:extension_with_delimiter).and_return('.pdf')
      allow(blob).to receive(:download) { |key, &block|
        10.times do |tmp|
          block.call('Test')
        end
      }
    end

    it 'processes the download in the expected order' do
      path = '/path/to/file'

      expect(Tempfile).to receive(:open).with(
        ['Ratonvirus', '.pdf'],
        subject.send(:tempdir)
      ).and_return(tempfile).ordered
      expect(tempfile).to receive(:binmode).ordered
      expect(tempfile).to receive(:write).exactly(10).times.ordered
      expect(tempfile).to receive(:flush).ordered
      expect(tempfile).to receive(:rewind).ordered
      expect(tempfile).to receive(:path).and_return(path).ordered
      expect(tempfile).to receive(:close!).ordered

      expect{ |b| method.call(blob, &b) }.to yield_with_args(path)
    end
  end

  describe '#tempdir' do
    let(:method) { subject.method(:tempdir) }

    it 'returns Dir.tmpdir' do
      expect(method.call).to eq(Dir.tmpdir)
    end
  end
end
