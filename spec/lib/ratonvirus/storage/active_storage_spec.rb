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
      allow(file).to receive_messages(record: file_record, name: "file")
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
      allow(resource).to receive(:is_a?).with(ActiveStorage::Attached::One)
                                        .and_return(true)
      expect(resource).to receive(:is_a?)
      expect(subject.accept?(resource)).to be(true)
    end

    it "returns true with ActiveStorage::Attached::Many" do
      allow(resource).to receive(:is_a?).with(ActiveStorage::Attached::One)
                                        .and_return(false)
      allow(resource).to receive(:is_a?).with(ActiveStorage::Attached::Many)
                                        .and_return(true)

      expect(resource).to receive(:is_a?).twice
      expect(subject.accept?(resource)).to be(true)
    end
  end

  describe "#process" do
    let(:resource) { double }
    let(:file_record) { double }
    let(:changes) { { "file" => single_change } }
    let(:single_change) { double }

    before do
      allow(resource).to receive_messages(attached?: true, record: file_record, name: "file")
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
          allow(ActiveStorage::Attached::Changes::CreateOne).to receive(:===).with(single_change).and_return(true)
          expect(ActiveStorage::Attached::Changes::CreateOne).to receive(:===).with(single_change)
        end

        context "without changed attachment" do
          it "does nothing" do
            allow(single_change).to receive(:attachable).and_return(nil)
            expect(single_change).to receive(:attachable)

            expect { |b| subject.process(resource, &b) }.not_to yield_control
          end
        end

        context "with changed attachment" do
          let(:change_attachable) { double("ble") }
          let(:change_attachment) { double("attachment") }

          before do
            allow(single_change).to receive_messages(attachable: change_attachable, attachment: change_attachment)
            expect(single_change).to receive(:attachable)
            expect(single_change).to receive(:attachment)
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
        let(:change_one) { double }
        let(:change_attachable_one) { double }
        let(:change_attachment_one) { double }
        let(:change_two) { double }
        let(:change_attachable_two) { double }
        let(:change_attachment_two) { double }

        before do
          allow(ActiveStorage::Attached::Changes::CreateOne).to receive(:===)
            .with(single_change).and_return(false)
          expect(ActiveStorage::Attached::Changes::CreateOne).to receive(:===)
            .with(single_change)
          allow(ActiveStorage::Attached::Changes::CreateMany).to receive(:===)
            .with(single_change).and_return(true)
          expect(ActiveStorage::Attached::Changes::CreateMany).to receive(:===)
            .with(single_change)

          allow(single_change).to receive(:pending_uploads).and_return([change_one, change_two])
          expect(single_change).to receive(:pending_uploads)
          expect(change_one).to receive(:attachable)
          allow(change_attachable_one).to receive(:is_a?).with(String).and_return(false)
          expect(change_attachable_one).to receive(:is_a?).twice
          allow(change_one).to receive_messages(attachable: change_attachable_one, attachment: change_attachment_one)
          expect(change_one).to receive(:attachment)
          expect(change_two).to receive(:attachable)
          allow(change_attachable_two).to receive(:is_a?).with(String).and_return(false)
          expect(change_attachable_two).to receive(:is_a?).twice
          allow(change_two).to receive_messages(attachable: change_attachable_two, attachment: change_attachment_two)
          expect(change_two).to receive(:attachment)
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
            case index
            when 1
              asset = processable.instance_variable_get(:@asset)
              expect(asset).to be_a(Array)
              expect(asset[0]).to eq(change_attachment_one)
              expect(asset[1]).to eq(change_attachable_one)
            when 2
              asset = processable.instance_variable_get(:@asset)
              expect(asset).to be_a(Array)
              expect(asset[0]).to eq(change_attachment_two)
              expect(asset[1]).to eq(change_attachable_two)
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
      let(:filename) { double }

      before do
        allow(attachment).to receive(:filename).and_return(filename)
        allow(filename).to receive(:extension_with_delimiter).and_return(".pdf")
        expect(attachment).to receive(:filename)
        expect(filename).to receive(:extension_with_delimiter)
      end

      context "with ActionDispatch::Http::UploadedFile" do
        let(:tempfile) { Tempfile.new }
        let(:attachable) do
          ActionDispatch::Http::UploadedFile.new(tempfile: tempfile)
        end

        it "yields with with the result of `path` of the attachable" do
          expect { |b| subject.asset_path(asset, &b) }.to yield_with_args(
            %r{/tmp/Ratonvirus[0-9]+-[0-9]+-[0-9a-z]+\.pdf}
          )
        end
      end

      context "with Rack::Test::UploadedFile" do
        let(:attachable) { Rack::Test::UploadedFile.new(ratonvirus_file_fixture("clean_file.pdf"), "application/pdf") }

        it "yields with with the result of `path` of the attachable" do
          expect { |b| subject.asset_path(asset, &b) }.to yield_with_args(
            %r{/tmp/Ratonvirus[0-9]+-[0-9]+-[0-9a-z]+\.pdf}
          )
        end
      end

      context "with Hash" do
        let(:file_io) { File.open(ratonvirus_file_fixture("clean_file.pdf")) }
        let!(:original_pos) { file_io.pos }
        let(:attachable) { { io: file_io } }

        it "yields with with the result of `path` of the attachable" do
          expect { |b| subject.asset_path(asset, &b) }.to yield_control
        end

        it "does not move the IO cursor position" do
          expect { |b| subject.asset_path(asset, &b) }.to yield_control
          expect(file_io.pos).to eq(original_pos)
        end
      end

      context "with ActiveStorage::Blob" do
        let(:attachable) { ActiveStorage::Blob.new }
        let(:tempfile) { Tempfile.new(["RatonTest", ".txt"]) }

        it "closes the file IO" do
          allow(attachable).to receive(:open).and_yield(tempfile)
          expect(attachable).to receive(:open)

          expect { |b| subject.asset_path(asset, &b) }.to yield_with_args(
            %r{/tmp/RatonTest[0-9]+-[0-9]+-[0-9a-z]+\.txt}
          )
        end
      end
    end
  end

  describe "#asset_remove" do
    let(:attachment) { double }
    let(:attachable) { double }
    let(:asset) { [attachment, attachable] }

    context "with ActionDispatch::Http::UploadedFile" do
      let(:tempfile) { Tempfile.new }
      let(:attachable) do
        ActionDispatch::Http::UploadedFile.new(tempfile: tempfile)
      end

      it "closes the tempfile" do
        expect(tempfile).to receive(:close!)
        subject.asset_remove(asset)
      end
    end

    context "with Rack::Test::UploadedFile" do
      let(:attachable) { Rack::Test::UploadedFile.new(ratonvirus_file_fixture("clean_file.pdf"), "application/pdf") }

      it "closes the tempfile" do
        expect(attachable.tempfile).to receive(:close!)
        subject.asset_remove(asset)
      end
    end

    context "with Hash" do
      let(:file_io) { File.open(ratonvirus_file_fixture("clean_file.pdf")) }
      let(:attachable) { { io: file_io } }

      it "closes the file IO" do
        expect(file_io).to receive(:close)
        subject.asset_remove(asset)
      end
    end

    context "with ActiveStorage::Blob" do
      let(:attachable) { ActiveStorage::Blob.new }

      it "closes the file IO" do
        expect(attachable).to receive(:purge)
        subject.asset_remove(asset)
      end
    end
  end

  describe "#tempdir" do
    let(:method) { subject.method(:tempdir) }

    it "returns Dir.tmpdir" do
      expect(method.call).to eq(Dir.tmpdir)
    end
  end
end
