# frozen_string_literal: true

require "spec_helper"

describe Ratonvirus::Scanner::Base do
  let(:config) { {} }
  let(:subject) { described_class.new(config) }

  it 'has callbacks defined' do
    expect(subject).to respond_to(:before_process_scan)
    expect(subject).to respond_to(:after_process_scan)
    expect(subject).to respond_to(:before_scan)
    expect(subject).to respond_to(:after_scan)
  end

  describe "#initialize" do
    it 'can be initialized with config' do
      expect(subject.config).to be_a(Hash)
    end

    it 'can be initialized without config' do
      subject = described_class.new
      expect(subject.config).to be_a(Hash)
    end

    it 'cannot be initialized without a hash' do
      expect{ described_class.new(nil) }.to raise_error(TypeError)
    end
  end

  describe '#setup' do
    context 'when force_availability is true' do
      let(:config) { {force_availability: true} }

      it 'sets availability to true' do
        expect(described_class).not_to receive(:executable?)

        subject
        expect(subject.available?).to be(true)
      end
    end

    context 'when force_availability is false' do
      let(:config) { {force_availability: false} }

      it 'it sets availability to true when scanner is executable' do
        expect(described_class).to receive(:executable?).and_return(true)

        subject
        expect(subject.available?).to be(true)
      end

      it 'it sets availability to false when scanner is not executable' do
        expect(described_class).to receive(:executable?).and_return(false)

        subject
        expect(subject.available?).to be(false)
      end
    end
  end

  describe '#config' do
    context 'with custom configuration' do
      let(:config) { {
        force_availability: true,
        extra: 'value',
      } }

      it 'accepts configuration' do
        expect(subject.config).to include(config)
        expect(subject.config.keys).to contain_exactly(*config.keys)
      end
    end
  end

  describe '#default_config' do
    let(:defaults) { subject.send(:default_config) }
    let(:expected) { {force_availability: false} }

    it 'has default configuration' do
      expect(subject.config).to include(defaults)
      expect(subject.config.keys).to contain_exactly(*defaults.keys)
    end

    it 'has expected default configuration' do
      expect(defaults).to be_a(Hash)
      expect(defaults).to include(expected)
      expect(defaults.keys).to contain_exactly(*expected.keys)
    end
  end

  describe '#errors' do
    it 'is nil by default' do
      expect(subject.errors).to be_nil
    end

    context 'calling run_scan' do
      context 'when no errors are added by run_scan' do
        it 'is empty' do
          allow(subject).to receive(:run_scan)

          subject.virus?('test')
          expect(subject.errors).to be_a(Array)
          expect(subject.errors).to be_empty
        end
      end

      context 'when errors are added by run_scan' do
        let(:scanner) do
          Class.new described_class do
            protected
              def run_scan(resource)
                errors << :err1
                errors << :err2
              end
          end
        end

        let(:subject) { scanner.new }

        it 'contains correct errors' do
          subject.virus?('test')
          expect(subject.errors).to contain_exactly(:err1, :err2)
        end
      end
    end
  end

  describe '#available?' do
    let(:config) { {force_availability: false} }

    it 'calls .executable? exactly once when not called before' do
      expect(described_class).to receive(:executable?).and_return(true)

      10.times do
        subject.available?
      end
    end
  end

  describe '#virus?' do
    let(:resource) { double }

    it 'calls scan' do
      expect(subject).to receive(:scan)

      subject.virus?('test')
    end

    it 'forces implementation to define run_scan' do
      expect{ subject.virus?('test') }.to raise_error(
        Ratonvirus::NotImplementedError
      )
    end

    it 'calls prepare in correct order' do
      expect(subject).to receive(:prepare).ordered
      expect(subject).to receive(:scan).ordered

      subject.virus?('test')
    end

    it 'calls storage in correct order' do
      storage = double
      allow(storage).to receive(:process)

      expect(subject).to receive(:prepare).ordered
      expect(subject).to receive(:storage).and_return(storage).ordered
      expect(storage).to receive(:process).and_yield(double).ordered
      expect(subject).to receive(:scan).ordered

      subject.virus?('test')
    end

    it 'passes result of storage.process result to scan' do
      processable = double

      storage = double
      allow(subject).to receive(:storage).and_return(storage)

      allow(storage).to receive(:process).and_yield(processable)
      expect(subject).to receive(:scan).with(processable)

      subject.virus?('test')
    end

    context 'when there are errors' do
      it 'returns true' do
        allow(subject).to receive(:scan) do
          subject.errors << :error
        end

        expect(subject.virus?('test')).to be(true)
      end
    end

    context 'when there are no errors' do
      it 'returns false' do
        allow(subject).to receive(:scan)

        expect(subject.virus?('test')).to be(false)
      end
    end

    context 'with callbacks' do
      it 'runs callbacks in correct order' do
        expect(subject).to receive(:call_this_before).ordered
        expect(subject).to receive(:scan).ordered
        expect(subject).to receive(:call_this_after).ordered

        subject.before_process_scan :call_this_before
        subject.after_process_scan :call_this_after

        subject.virus?('test')
      end

      it 'passes the resource to the callbacks' do
        resource = double

        expect(subject).to receive(:call_this_before).with(resource).ordered
        expect(subject).to receive(:scan).ordered
        expect(subject).to receive(:call_this_after).with(resource).ordered

        subject.before_process_scan :call_this_before
        subject.after_process_scan :call_this_after

        subject.virus?(resource)
      end

      it 'ensures errors when scanning results raises an error' do
        expect(subject).to receive(:scan) do
          subject.errors << :sample_error
          raise StandardError
        end

        expect{ subject.virus?(resource) }.to raise_error(StandardError)

        expect(subject.errors).to include(:sample_error)
      end

      it 'only contains unique errors' do
        expect(subject).to receive(:scan) do
          subject.errors << :sample_error
          subject.errors << :sample_error
          subject.errors << :sample_error
          subject.errors << :sample_error
        end

        subject.virus?('test')

        expect(subject.errors.length).to eq(1)
      end
    end
  end

  context 'with addons' do
    before(:each) do
      Ratonvirus.configure do |config|
        config.addons = [:remove_infected]
      end
    end

    it 'applies addons on preparation' do
      allow(subject).to receive(:run_scan)
      expect(subject).to receive(:extend).and_call_original
      expect(Ratonvirus::Scanner::Addon::RemoveInfected).to receive(:extended)
        .with(subject)

      subject.virus?('test')
    end

    it 'applies addons only on first preparation' do
      how_many = 10

      expect(subject).to receive(:run_scan).exactly(how_many).times
      expect(Ratonvirus.addons).to receive(:each).and_call_original.once

      how_many.times do
        subject.virus?('test')
      end
    end
  end
end
