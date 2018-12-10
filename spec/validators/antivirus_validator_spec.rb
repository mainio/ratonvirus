# frozen_string_literal: true

require "spec_helper_rails"

describe AntivirusValidator do
  let(:validatable) do
    Class.new do
      # Without this, the validator would require a name option to be passed
      # to it.
      def self.model_name
        ActiveModel::Name.new(self, nil, "Validatable")
      end

      # Testing the validators
      include ActiveModel::Validations

      attr_accessor :file

      # Attach the validator to the model
      validates :file, antivirus: true
    end
  end
  let(:subject) { validatable.new }
  let(:storage) { double }

  context 'when storage does not accept the resource' do
    before(:each) do
      expect(Ratonvirus).to receive(:storage).and_return(storage).ordered
      expect(storage).to receive(:accept?).and_return(false).ordered
      expect(storage).not_to receive(:changed?)
      expect(Ratonvirus).not_to receive(:scanner)
    end

    it { is_expected.to be_valid }
  end

  context 'when file is not changed' do
    before(:each) do
      expect(Ratonvirus).to receive(:storage).and_return(storage).ordered
      expect(storage).to receive(:accept?).and_return(true).ordered
      expect(storage).to receive(:changed?).and_return(false).ordered
      expect(Ratonvirus).not_to receive(:scanner)
    end

    it { is_expected.to be_valid }
  end

  context 'when file is changed and accepted' do
    let(:scanner) { double }

    before(:each) do
      expect(Ratonvirus).to receive(:storage).and_return(storage).ordered
      expect(storage).to receive(:accept?).and_return(true).ordered
      expect(storage).to receive(:changed?).and_return(true).ordered
      expect(Ratonvirus).to receive(:scanner).and_return(scanner).ordered
    end

    context 'with unavailable scanner' do
      before(:each) do
        expect(scanner).to receive(:available?).and_return(false).ordered
        expect(scanner).not_to receive(:virus?)
      end

      it { is_expected.to be_valid }
    end

    context 'with available scanner' do
      before(:each) do
        expect(scanner).to receive(:available?).and_return(true).ordered
      end

      context 'not detecting a virus' do
        before(:each) do
          expect(scanner).to receive(:virus?).and_return(false).ordered
          expect(scanner).not_to receive(:errors)
        end

        it { is_expected.to be_valid }
      end

      context 'detecting a virus' do
        before(:each) do
          expect(scanner).to receive(:virus?).and_return(true).ordered
        end

        context 'with no errors added' do
          before(:each) do
            expect(scanner).to receive(:errors).once.and_return([]).ordered
          end

          it 'should not pass and should contain default error' do
            is_expected.not_to be_valid
            expect(subject.errors.details[:file]).to contain_exactly(
              {error: :antivirus_virus_detected}
            )
          end
        end

        context 'with added errors' do
          before(:each) do
            expect(scanner).to receive(:errors).twice.and_return([
              :first_error,
              :second_error
            ]).ordered
          end

          it 'should not pass and should contain added errors' do
            is_expected.not_to be_valid
            expect(subject.errors.details[:file]).to contain_exactly(
              {error: :first_error},
              {error: :second_error},
            )
          end
        end

        context 'with all default errors' do
          before(:each) do
            expect(scanner).to receive(:errors).twice.and_return([
              :antivirus_virus_detected,
              :antivirus_client_error,
              :antivirus_file_not_found,
            ]).ordered
          end

          it 'adds correct error translations' do
            is_expected.not_to be_valid
            expect(subject.errors[:file]).to contain_exactly(
              'contains a virus',
              'could not be processed for virus scan',
              'could not be found for virus scan',
            )
          end
        end
      end
    end
  end
end
