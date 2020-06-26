# frozen_string_literal: true

require "rails_helper"

describe Ratonvirus::Storage::ActiveStorage do
  describe "#changed?" do
    let(:record) { double }
    let(:file) { double }
    let(:file_record) { double }
    let(:changes) { {} }
    let(:single_change) { double }

    before do
      allow(record).to receive(:file).and_return(file)
      allow(file).to receive(:record).and_return(file_record)
      allow(file).to receive(:name).and_return("file")
      allow(file_record).to receive(:attachment_changes).and_return(changes)
    end

    context "when record is changed" do
      let(:changes) { { "file" => single_change } }

      it "returns true" do
        expect(subject.changed?(record, :file)).to be(true)
      end
    end

    context "when record is not changed" do
      it "returns false" do
        expect(subject.changed?(record, :file)).to be(false)
      end
    end
  end

  describe "#accept?" do
    let(:resource) { double }

    it "returns true with ActiveStorage::Attached::One" do
      expect(resource).to receive(:is_a?).with(ActiveStorage::Attached::One)
                                         .and_return(true)

      expect(subject.accept?(resource)).to be(true)
    end

    it "returns true with ActiveStorage::Attached::Many" do
      expect(resource).to receive(:is_a?).with(ActiveStorage::Attached::One)
                                         .and_return(false)
      expect(resource).to receive(:is_a?).with(ActiveStorage::Attached::Many)
                                         .and_return(true)

      expect(subject.accept?(resource)).to be(true)
    end
  end

  describe "#process" do
    let(:resource) { double }
    let(:file_record) { double }
    let(:changes) { { "file" => single_change } }
    let(:single_change) { double }

    before do
      allow(resource).to receive(:attached?).and_return(true)
      allow(resource).to receive(:record).and_return(file_record)
      allow(resource).to receive(:name).and_return("file")
      allow(file_record).to receive(:attachment_changes).and_return(changes)
    end

    context "with no block given" do
      it "returns without doing anything" do
        expect(resource).not_to receive(:record)
        subject.process(resource)
      end
    end

    context "when resource is attached" do
      context "with ActiveStorage::Attached::One" do
        let(:attachment) { double }

        before do
          expect(single_change).to receive(:is_a?)
            .with(ActiveStorage::Attached::Changes::CreateOne).and_return(true)
        end

        context "without changed attachment" do
          it "does nothing" do
            expect(single_change).to receive(:attachable).and_return(nil)

            expect { |b| subject.process(resource, &b) }.not_to yield_control
          end
        end

        context "with changed attachment" do
          let(:change_attachable) { double }
          let(:change_attachment) { double }

          before do
            expect(single_change).to receive(:attachable).and_return(change_attachable).twice
            expect(single_change).to receive(:attachment).and_return(change_attachment)
          end

          it "calls processable and yields the result" do
            expect { |b| subject.process(resource, &b) }.to yield_with_args(Ratonvirus::Processable)
          end

          it "calls processable and yields the processable with correct resource" do
            subject.process(resource) do |processable|
              asset = processable.instance_variable_get(:@asset)
              expect(asset).to be_a(Array)
              expect(asset[0]).to eq(change_attachment)
              expect(asset[1]).to eq(change_attachable)
            end
          end
        end
      end

      context "with ActiveStorage::Attached::Many" do
        let(:change1) { double }
        let(:change_attachable_1) { double }
        let(:change_attachment_1) { double }
        let(:change2) { double }
        let(:change_attachable_2) { double }
        let(:change_attachment_2) { double }
        let(:subchanges) { [change1, change2] }

        before do
          expect(single_change).to receive(:is_a?)
            .with(ActiveStorage::Attached::Changes::CreateOne).and_return(false)
          expect(single_change).to receive(:is_a?)
            .with(ActiveStorage::Attached::Changes::CreateMany).and_return(true)
          expect(single_change).to receive(:subchanges).and_return(subchanges)
          expect(change1).to receive(:attachable).and_return(change_attachable_1).exactly(3).times
          expect(change_attachable_1).to receive(:is_a?).with(ActiveStorage::Blob).and_return(false)
          expect(change1).to receive(:attachment).and_return(change_attachment_1)
          expect(change2).to receive(:attachable).and_return(change_attachable_2).exactly(3).times
          expect(change_attachable_2).to receive(:is_a?).with(ActiveStorage::Blob).and_return(false)
          expect(change2).to receive(:attachment).and_return(change_attachment_2)
        end

        it "calls processable and yields the result" do
          expect { |b| subject.process(resource, &b) }.to yield_successive_args(
            Ratonvirus::Processable,
            Ratonvirus::Processable
          )
        end

        it "calls processable for all changes and yields the correct resources" do
          index = 1
          subject.process(resource) do |processable|
            if index == 1
              asset = processable.instance_variable_get(:@asset)
              expect(asset).to be_a(Array)
              expect(asset[0]).to eq(change_attachment_1)
              expect(asset[1]).to eq(change_attachable_1)
            elsif index == 2
              asset = processable.instance_variable_get(:@asset)
              expect(asset).to be_a(Array)
              expect(asset[0]).to eq(change_attachment_2)
              expect(asset[1]).to eq(change_attachable_2)
            end

            index += 1
          end
        end
      end
    end
  end

  describe "#asset_path" do
    let(:attachment) { double }
    let(:attachable) { double }
    let(:asset) { [attachment, attachable] }

    context "when block is not provided" do
      it "does not do anything" do
        expect(asset).not_to receive(:is_a?)
        subject.asset_path(asset)
      end
    end

    context "when block is provided" do
      let(:attachment) { double }
      let(:asset) { [attachment, attachable] }

      context "with an unknown asset" do
        it "does not yield" do
          expect(asset).to receive(:is_a?).with(Array).and_return(true)
          expect(asset).not_to receive(:blob)
          expect { |b| subject.asset_path(asset, &b) }.not_to yield_control
        end
      end

      context "with ActionDispatch::Http::UploadedFile" do
        let(:tempfile) { Tempfile.new }
        let(:attachable) do
          ActionDispatch::Http::UploadedFile.new(tempfile: tempfile)
        end

        it "yields with with the result of `path` of the attachable" do
          expect { |b| subject.asset_path(asset, &b) }.to yield_with_args(
            tempfile.path
          )
        end
      end

      context "with Rack::Test::UploadedFile" do
        let(:attachable) { fixture_file_upload("files/clean_file.pdf") }

        it "yields with with the result of `path` of the attachable" do
          expect { |b| subject.asset_path(asset, &b) }.to yield_with_args(
            attachable.path
          )
        end
      end

      context "with Hash" do
        let(:file_io) { File.open(file_fixture("clean_file.pdf")) }
        let(:attachable) { { io: file_io } }

        it "yields with with the result of `path` of the attachable" do
          filename = double
          expect(attachment).to receive(:filename).and_return(filename)
          expect(filename).to receive(:extension_with_delimiter).and_return(".pdf")

          expect { |b| subject.asset_path(asset, &b) }.to yield_control
        end
      end
    end
  end

  describe "#asset_remove" do
    let(:attachment) { double }
    let(:attachable) { double }
    let(:asset) { [attachment, attachable] }

    it "calls asset.purge" do
      expect(attachment).to receive(:purge)
      subject.asset_remove(asset)
    end
  end

  describe "#tempdir" do
    let(:method) { subject.method(:tempdir) }

    it "returns Dir.tmpdir" do
      expect(method.call).to eq(Dir.tmpdir)
    end
  end
end
