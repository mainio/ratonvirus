# frozen_string_literal: true

require "spec_helper"

describe Ratonvirus::Storage::Base do
  describe "#initalize" do
    it "initializes without parameters" do
      expect(subject.config).to be_empty
    end

    it "duplicates the configuration" do
      config = {}
      subject = described_class.new(config)

      expect(subject.config).not_to equal(config)
    end
  end

  describe "#process" do
    let(:resource) { double }

    context "when block is not given" do
      it "returns before calling resource.nil?" do
        expect(resource).not_to receive(:nil?)
        subject.process(resource)
      end
    end

    context "when block is given" do
      let(:processable) { double }

      before do
        expect(resource).to receive(:nil?).ordered
      end

      context "with non-array resource" do
        before do
          expect(resource).to receive(:is_a?).with(Array)
            .ordered.and_return(false)
        end

        it "passes the resource to processable and yields" do
          expect(subject).to receive(:processable).with(resource)
            .ordered.and_return(processable)

          expect { |b| subject.process(resource, &b) }
            .to yield_with_args(processable)
        end
      end

      context "with array resource" do
        let(:resource) { [double, double, double] }

        before do
          expect(resource).to receive(:is_a?)
            .with(Array).ordered.and_call_original
        end

        it "yields the correct number of times" do
          resource.each do |r|
            expect(subject).to receive(:processable).with(r).ordered
          end

          expect { |b| subject.process(resource, &b) }
            .to yield_control.exactly(3).times
        end
      end
    end
  end

  describe "#changed?" do
    it do
      expect { subject.changed?(double, :file) }.to(
        raise_error(Ratonvirus::NotImplementedError)
      )
    end
  end

  describe "#accept?" do
    it do
      expect { subject.accept?("test") }.to(
        raise_error(Ratonvirus::NotImplementedError)
      )
    end
  end

  describe "#asset_path" do
    it do
      expect { subject.asset_path("test") }.to(
        raise_error(Ratonvirus::NotImplementedError)
      )
    end
  end

  describe "#asset_remove" do
    it do
      expect { subject.asset_remove("test") }.to(
        raise_error(Ratonvirus::NotImplementedError)
      )
    end
  end

  describe "#processable" do
    let(:method) { subject.method(:processable) }

    let(:asset) { double }
    let(:processable) { double }

    it "calls Processable.new with correct arguments" do
      expect(Ratonvirus::Processable).to receive(:new)
        .with(subject, asset).and_return(processable)

      expect(method.call(asset)).to equal(processable)
    end
  end
end
