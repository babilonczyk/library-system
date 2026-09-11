require "rails_helper"

RSpec.describe CatalogManagement::BookQueryService do
  describe "with no filter" do
    it "returns every book still in the catalogue" do
      kept = create(:book)
      create(:book, :withdrawn)

      expect(described_class.call[:books]).to contain_exactly(kept)
    end

    it "orders by title" do
      create(:book, title: "Ubik")
      create(:book, title: "Dune")
      create(:book, title: "Solaris")

      expect(described_class.call[:books].map(&:title)).to eq([ "Dune", "Solaris", "Ubik" ])
    end
  end

  describe "with available: true" do
    it "returns only books nobody has out" do
      free = create(:book)
      create(:book, :borrowed)

      expect(described_class.call(available: "true")[:books]).to contain_exactly(free)
    end

    it "counts a book as free again once it is returned" do
      returned = create(:book)
      create(:loan, book: returned, returned_on: Date.current)

      expect(described_class.call(available: "true")[:books]).to contain_exactly(returned)
    end
  end

  describe "with available: false" do
    it "returns only books currently out" do
      out = create(:book, :borrowed)
      create(:book)

      expect(described_class.call(available: "false")[:books]).to contain_exactly(out)
    end

    it "still excludes withdrawn books" do
      withdrawn = create(:book, :withdrawn)
      create(:loan, book: withdrawn)

      expect(described_class.call(available: "false")[:books]).to be_empty
    end
  end

  describe "with a value it does not recognise" do
    it "refuses rather than guessing" do
      expect(described_class.call(available: "banana")).to eq(error: :invalid_availability_filter)
    end
  end
end
