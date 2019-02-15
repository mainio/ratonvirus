# frozen_string_literal: true

require "spec_helper"

describe Ratonvirus::Processable do
  let(:subject) { described_class.new(storage, asset) }
  let(:storage) { double }
  let(:asset) { double }

  describe "#path" do
    it "when block is not provided does not call storage.asset_path" do
      expect(storage).not_to receive(:asset_path)
      subject.path
    end

    it "when block is provided calls storage.asset_path" do
      block = proc {}
      expect(storage).to receive(:asset_path).with(asset, &block)
      subject.path(&block)
    end
  end

  describe "#remove" do
    it "calls storage.asset_remove" do
      expect(storage).to receive(:asset_remove).with(asset)
      subject.remove
    end
  end
end
