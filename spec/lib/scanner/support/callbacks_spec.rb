# frozen_string_literal: true

require "spec_helper"

describe Ratonvirus::Scanner::Support::Callbacks do
  let(:subject) { double }

  before(:each) do
    subject.extend(described_class)
  end

  describe '#define_callbacks' do
    before(:each) do
      subject.send(:define_callbacks, :one)
      subject.send(:define_callbacks, :two)
      subject.send(:define_callbacks, :three)
    end

    it 'defines the before methods' do
      expect(subject).to respond_to(:before_one)
      expect(subject).to respond_to(:before_two)
      expect(subject).to respond_to(:before_three)
    end

    it 'defines the after methods' do
      expect(subject).to respond_to(:after_one)
      expect(subject).to respond_to(:after_two)
      expect(subject).to respond_to(:after_three)
    end

    it 'adds before type callables' do
      subject.before_one :first_before
      subject.before_one :second_before

      cbs = subject.instance_variable_get(:@_callbacks)
      expect(cbs).to include({
        one: {after: [], before: [:first_before, :second_before]},
        two: {after: [], before: []},
        three: {after: [], before: []},
      })
    end

    it 'adds after type callables' do
      subject.after_one :first_after
      subject.after_one :second_after

      cbs = subject.instance_variable_get(:@_callbacks)
      expect(cbs).to include({
        one: {after: [:first_after, :second_after], before: []},
        two: {after: [], before: []},
        three: {after: [], before: []},
      })
    end
  end

  describe '#run_callbacks' do
    let(:run) { subject.method(:run_callbacks) }

    context 'when callbacks are not defined' do
      it 'raises a Ratonvirus::NotDefinedError' do
        expect{ run.call(:undefined) }.to raise_error(
          Ratonvirus::NotDefinedError, "No callbacks defined"
        )
      end
    end

    context 'when callbacks are defined' do
      before(:each) do
        subject.send(:define_callbacks, :hook)
      end

      it 'calls the before and after methods in correct order' do
        subject.before_hook :do_before
        subject.after_hook :do_after

        expect(subject).to receive(:do_before).ordered
        expect(subject).to receive(:do_something).ordered
        expect(subject).to receive(:do_after).ordered

        run.call :hook do
          subject.do_something
        end
      end

      it 'passes the extra arguments to the before callback' do
        subject.before_hook :do_before
        args = [1, 2, 3]

        allow(subject).to receive(:do_something)
        expect(subject).to receive(:do_before).with(*args)

        run_result = run.call :hook, *args do
          subject.do_something
        end
      end

      it 'passes the extra arguments to the after callback' do
        subject.after_hook :do_after
        args = [1, 2, 3]

        allow(subject).to receive(:do_something)
        expect(subject).to receive(:do_after).with(*args)

        run_result = run.call :hook, *args do
          subject.do_something
        end
      end

      it 'returns the result of the block' do
        result = ('a'..'z').to_a.shuffle.join
        expect(subject).to receive(:do_something).and_return(result)

        run_result = run.call :hook do
          subject.do_something
        end

        expect(run_result).to equal(result)
      end

      context 'and trying to invoke another undefined callback' do
        it 'raises a Ratonvirus::NotDefinedError' do
          expect{ run.call(:undefined) }.to raise_error(
            Ratonvirus::NotDefinedError, "Callbacks for undefined not defined"
          )
        end
      end
    end
  end

  describe '#run_callback_callables' do
    let(:run) { subject.method(:run_callback_callables) }

    it 'runs the callables without arguments' do
      expect(subject).to receive(:do_something).with(no_args).ordered
      expect(subject).to receive(:do_something_else).with(no_args).ordered

      run.call([:do_something, :do_something_else])
    end

    it 'runs the callables with arguments and passes the arguments' do
      args = [1, 2, 3]
      expect(subject).to receive(:do_something).with(*args).ordered
      expect(subject).to receive(:do_something_else).with(*args).ordered

      run.call([:do_something, :do_something_else], *args)
    end
  end
end
