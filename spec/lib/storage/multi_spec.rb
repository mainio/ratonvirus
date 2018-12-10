# frozen_string_literal: true

require "spec_helper"

describe Ratonvirus::Storage::Multi do
  describe "#setup" do
    before(:each) do
      subject.instance_variable_set(:@config, config)
    end

    context 'with no config provided' do
      let(:config) { {} }

      it 'calls for the config array once' do
        expect(subject).to receive(:config).and_call_original
        subject.setup
      end
    end

    context 'with invalid config provided' do
      let(:config) { {storages: :active_storage} }

      it 'calls for the config array once' do
        expect(subject).to receive(:config).and_call_original
        subject.setup
      end
    end

    context 'with no keys provided' do
      let(:config) { {storages: []} }

      it 'calls for the config array twice' do
        expect(subject).to receive(:config).twice.and_call_original
        subject.setup
      end
    end

    context 'with only storage keys provided' do
      let(:config) { {storages: [:active_storage, :filepath]} }

      it 'calls for the config array twice and ' do
        expect(subject).to receive(:config).twice.ordered.and_call_original
        expect(Ratonvirus).to receive(:backend_class)
          .with('Storage', :active_storage).ordered.and_call_original
        expect(Ratonvirus::Storage::ActiveStorage).to receive(:new).with({})
          .ordered
        expect(Ratonvirus).to receive(:backend_class).ordered
          .with('Storage', :filepath).and_call_original
        expect(Ratonvirus::Storage::Filepath).to receive(:new).with({}).ordered

        subject.setup

        expect(subject.instance_variable_get(:@storages).length).to eq(2)
      end
    end

    context 'with storage keys and config provided' do
      let(:config) { {storages: [
        [:active_storage, {conf: 'option'}],
        [:filepath, {conf2: 'option2'}]
      ]} }

      it 'calls for the config array twice and ' do
        expect(subject).to receive(:config).twice.ordered.and_call_original
        expect(Ratonvirus).to receive(:backend_class)
          .with('Storage', :active_storage).ordered.and_call_original
        expect(Ratonvirus::Storage::ActiveStorage).to receive(:new)
          .with({conf: 'option'}).ordered
        expect(Ratonvirus).to receive(:backend_class).ordered
          .with('Storage', :filepath).and_call_original
        expect(Ratonvirus::Storage::Filepath).to receive(:new)
          .with({conf2: 'option2'}).ordered

        subject.setup

        expect(subject.instance_variable_get(:@storages).length).to eq(2)
      end
    end
  end

  context '#process' do
    let(:resource) { subject }

    context 'when block is not given' do
      it 'should not call storage_for' do
        expect(subject).not_to receive(:storage_for)
        subject.process(resource)
      end
    end

    context 'when block is given' do
      let(:storage) { double }
      let(:block) { Proc.new {} }

      before(:each) do
        expect(subject).to receive(:storage_for).with(resource)
          .and_yield(storage)
      end

      it 'should call process on the underlying storage' do
        expect(storage).to receive(:process).with(resource, &block)
        subject.process(resource, &block)
      end
    end
  end

  context '#changed?' do
    let(:record) { double }
    let(:attribute) { :test }
    let(:resource) { double }

    before(:each) do
      expect(record).to receive(:public_send).with(attribute)
        .and_return(resource)
    end

    context 'when storage_for does not yield' do
      it 'should return false' do
        expect(subject).to receive(:storage_for).with(resource)
        expect(subject.changed?(record, attribute)).to be(false)
      end
    end

    context 'when storage_for yields' do
      let(:storage) { double }

      before(:each) do
        expect(subject).to receive(:storage_for).with(resource)
          .and_yield(storage)
      end

      it 'should call changed? on the underlying storage' do
        changed = double
        expect(storage).to receive(:changed?).with(record, attribute)
          .and_return(changed)

        expect(subject.changed?(record, attribute)).to be(changed)
      end
    end
  end

  context '#accept?' do
    let(:resource) { double }

    context 'when storage_for does not yield' do
      it 'should return false' do
        expect(subject).to receive(:storage_for).with(resource)
        expect(subject.accept?(resource)).to be(false)
      end
    end

    context 'when storage_for yields' do
      let(:storage) { double }

      it 'should return false' do
        expect(subject).to receive(:storage_for).with(resource)
          .and_yield(storage)
        expect(subject.accept?(resource)).to be(true)
      end
    end
  end

  context '#storage_for' do
    let(:method) { subject.method(:storage_for) }
    let(:resource) { double }

    context 'when storages has' do
      let(:storage) { double }

      before(:each) do
        subject.instance_variable_set(:@storages, storages)
      end

      context 'single item' do
        let(:storage) { double }
        let(:storages) { [storage] }

        it 'should not yield if storage.accept? returns false' do
          expect(storage).to receive(:accept?).with(resource).and_return(false)
          expect{ |b| method.call(resource, &b) }.not_to yield_control
        end
      end

      context 'multiple items' do
        let(:storage1) { double }
        let(:storage2) { double }
        let(:storage3) { double }
        let(:storages) { [storage1, storage2, storage3] }

        it 'should yield only on the first storage if it accepts the resource' do
          expect(storage1).to receive(:accept?).with(resource).and_return(true)
          expect(storage2).not_to receive(:accept?)
          expect(storage3).not_to receive(:accept?)

          expect{ |b| method.call(resource, &b) }.to yield_with_args(storage1)
        end

        it 'should yield on the first and second storage if second one accepts the resource' do
          expect(storage1).to receive(:accept?).with(resource).and_return(false)
          expect(storage2).to receive(:accept?).with(resource).and_return(true)
          expect(storage3).not_to receive(:accept?)

          expect{ |b| method.call(resource, &b) }.to yield_with_args(storage2)
        end

        it 'should yield on all the storages if the last one accepts the resource' do
          expect(storage1).to receive(:accept?).with(resource).and_return(false)
          expect(storage2).to receive(:accept?).with(resource).and_return(false)
          expect(storage3).to receive(:accept?).with(resource).and_return(true)

          expect{ |b| method.call(resource, &b) }.to yield_with_args(storage3)
        end

        it 'should not yield if all the storages reject the resource' do
          expect(storage1).to receive(:accept?).with(resource).and_return(false)
          expect(storage2).to receive(:accept?).with(resource).and_return(false)
          expect(storage3).to receive(:accept?).with(resource).and_return(false)

          expect{ |b| method.call(resource, &b) }.not_to yield_control
        end
      end
    end
  end
end
