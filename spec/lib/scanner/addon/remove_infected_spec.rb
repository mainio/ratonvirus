# frozen_string_literal: true

require "spec_helper"

describe Ratonvirus::Scanner::Addon::RemoveInfected do
  let(:subject) { double }

  describe '.extended' do
    it 'is called when addon is applied' do
      expect(described_class).to receive(:extended).with(subject)
      subject.extend described_class
    end

    it 'calls .after_scan on the extended object with correct arguments' do
      expect(subject).to receive(:after_scan).with(:remove_infected_file)
      subject.extend described_class
    end
  end

  describe '#remove_infected_file' do
    let(:method) { subject.method(:remove_infected_file) }
    let(:processable) { double }

    before(:each) do
      expect(subject).to receive(:after_scan)
      subject.extend described_class
    end

    describe 'when virus is not detected' do
      before(:each) do
        expect(subject).to receive(:errors).and_return([])
      end

      it 'does not call storage' do
        expect(processable).not_to receive(:remove)
        method.call('test')
      end
    end

    context 'when virus is detected' do
      before(:each) do
        expect(subject).to receive(:errors).and_return(
          [:antivirus_virus_detected]
        )
      end

      it 'calls storage.remove with the given resource' do
        expect(processable).to receive(:remove)
        method.call(processable)
      end
    end
  end
end
