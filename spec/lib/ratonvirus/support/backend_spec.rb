# frozen_string_literal: true

require "spec_helper"

describe Ratonvirus::Support::Backend do
  let(:namespace) { "Foo" }
  let(:backend_type) { :test }

  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) do
    # Define the base level module
    described_mod = described_class
    mod = Module.new do
      extend described_mod
    end

    # Define the second level namespace as ...::Foo
    foo = Module.new
    mod.const_set("Foo", foo)

    # Define the final base class ...::Foo::Base
    base = Class.new do
      def config
        {}
      end
    end
    foo.const_set("Base", base)

    # Define the base level module as RatonvirusTest in the global namespace.
    #
    # After this the following are available:
    #   RatonvirusTest => Module
    #   RatonvirusTest::Foo => Module
    #   RatonvirusTest::Foo::Base => Class
    Object.const_set("RatonvirusTest", mod)
  end
  # rubocop:enable RSpec/BeforeAfterAll

  describe ".backend_class" do
    let(:method) { RatonvirusTest.method(:backend_class) }

    context "with Class backend_type" do
      it "returns the class itself" do
        cls = Class.new
        expect(method.call(namespace, cls)).to equal(cls)
      end
    end

    context "with symbol backend_type" do
      it "returns the the correct constant" do
        expect(method.call(namespace, :base)).to equal(
          RatonvirusTest::Foo::Base
        )
      end
    end

    context "with unknown backend_type" do
      it "returns the the correct constant" do
        expect { method.call(namespace, :unknown) }.to raise_error(NameError)
      end
    end
  end

  describe ".set_backend" do
    let(:method) { RatonvirusTest.method(:set_backend) }

    context "with Class backend_value" do
      it "sets the backend correctly" do
        cls = RatonvirusTest::Foo::Base.new

        expect(RatonvirusTest).to receive(:instance_variable_set).with(
          :@test,
          cls
        ).and_call_original
        expect(RatonvirusTest).to receive(:instance_variable_set).with(
          :@test_defs,
          klass: RatonvirusTest::Foo::Base,
          config: {}
        ).and_call_original

        method.call(backend_type, namespace, cls)
      end
    end

    context "with Array backend_value" do
      context "with config" do
        it "sets the backend correctly" do
          config = { conf: "option" }

          expect(RatonvirusTest).to receive(:destroy_test)
          expect(RatonvirusTest).to receive(:instance_variable_set).with(
            :@test_defs,
            klass: RatonvirusTest::Foo::Base,
            config: config
          ).and_call_original

          method.call(backend_type, namespace, [:base, config])
        end
      end

      context "without config" do
        it "sets the backend correctly" do
          expect(RatonvirusTest).to receive(:destroy_test)
          expect(RatonvirusTest).to receive(:instance_variable_set).with(
            :@test_defs,
            klass: RatonvirusTest::Foo::Base,
            config: {}
          ).and_call_original

          method.call(backend_type, namespace, [:base])
        end
      end

      context "with non-symbol backend_value" do
        it "raises Ratonvirus::InvalidError" do
          expect do
            method.call(backend_type, namespace, ["base"])
          end.to raise_error(Ratonvirus::InvalidError)
        end
      end
    end

    context "with Symbol backend_value" do
      it "sets the backend correctly" do
        expect(RatonvirusTest).to receive(:destroy_test)
        expect(RatonvirusTest).to receive(:instance_variable_set).with(
          :@test_defs,
          klass: RatonvirusTest::Foo::Base,
          config: {}
        ).and_call_original

        method.call(backend_type, namespace, :base)
      end
    end

    context "with other backend_value" do
      it "raises Ratonvirus::InvalidError" do
        expect(RatonvirusTest).not_to receive(:destroy_test)
        expect do
          method.call(backend_type, namespace, "base")
        end.to raise_error(Ratonvirus::InvalidError)
      end
    end
  end

  describe ".define_backend" do
    let(:subject) { Module.new }

    before do
      subject.extend described_class
      subject.send(:define_backend, backend_type, namespace)
    end

    it "defines all expected methods" do
      expect(subject.respond_to?(:test)).to be(true)
      expect(subject.respond_to?(:test=)).to be(true)
      expect(subject.respond_to?(:destroy_test)).to be(true)
      expect(subject.respond_to?(:create_test)).to be(false)
      expect(subject.respond_to?(:create_test, true)).to be(true)
    end

    describe ".test" do
      it "defines an instance variable on first call" do
        backend = RatonvirusTest::Foo::Base.new
        expect(subject).to receive(:create_test).and_return(backend)
        expect(subject.instance_variable_get(:@test)).to be_nil

        subject.test
        expect(subject.instance_variable_get(:@test)).to equal(backend)
      end

      it "defines an instance variable only on first call" do
        expect(subject).to receive(:create_test).and_return(true).once

        5.times do
          subject.test
        end
      end
    end

    describe ".test=" do
      it "calls set_backend with correct attributes" do
        expect(subject).to receive(:set_backend).with(
          backend_type,
          namespace,
          :base
        )

        subject.test = :base
      end
    end

    describe ".destroy_test" do
      it "unsets the backend variable" do
        subject.instance_variable_set(:@test, true)
        subject.destroy_test

        expect(subject.instance_variable_get(:@test)).to be_nil
      end
    end

    describe ".create_test" do
      let(:method) { subject.method(:create_test) }

      context "when backend has not been defined" do
        it "raises Ratonvirus::NotDefinedError" do
          expect { method.call }.to raise_error(Ratonvirus::NotDefinedError)
        end
      end

      context "when backend has been defined" do
        let(:backend) { Class.new }
        let(:backend_config) { { conf: "option" } }

        before do
          # Define the class
          Object.const_set("BackendSpecTestBackend", backend)

          subject.instance_variable_set(
            :@test_defs,
            klass: BackendSpecTestBackend,
            config: backend_config
          )
        end

        it "creates a new instance of the backend" do
          expect(backend).to receive(:new).with(backend_config)
          method.call
        end
      end
    end
  end
end
