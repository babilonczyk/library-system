require "rails_helper"

RSpec.describe Core::BaseService do
  describe ".call" do
    it "builds an instance and returns what its call returns" do
      stub_const("GreetService", Class.new(described_class) do
        def call
          :greeted
        end
      end)

      expect(GreetService.call).to eq(:greeted)
    end

    it "passes keyword arguments through, defaults included" do
      stub_const("EchoService", Class.new(described_class) do
        def initialize(book:, on: "default")
          @book = book
          @on = on
        end

        def call
          [ @book, @on ]
        end
      end)

      aggregate_failures do
        expect(EchoService.call(book: "Dune")).to eq([ "Dune", "default" ])
        expect(EchoService.call(book: "Dune", on: "2026-12-01")).to eq([ "Dune", "2026-12-01" ])
      end
    end

    it "refuses positional arguments, so every call site names what it passes" do
      stub_const("PositionalService", Class.new(described_class) do
        def initialize(book)
          @book = book
        end

        def call
          @book
        end
      end)

      expect { PositionalService.call("Dune") }.to raise_error(ArgumentError)
    end
  end

  describe "#call" do
    it "raises, naming the subclass that failed to implement it" do
      stub_const("ForgetfulService", Class.new(described_class))

      expect { ForgetfulService.call }
        .to raise_error(NotImplementedError, "ForgetfulService must implement #call")
    end
  end
end
