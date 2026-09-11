require "rails_helper"

RSpec.describe BookSerializer do
  let(:book) do
    create(:book, title: "Solaris", author: "Stanisław Lem", serial_number: "200003")
  end

  describe "the list shape" do
    it "renders the book and whether it can be borrowed" do
      expected = { "id" => book.id,
                   "title" => "Solaris",
                   "author" => "Stanisław Lem",
                   "serial_number" => "200003",
                   "available" => true }

      expect(JSON.parse(described_class.new(book).serialize)).to eq(expected)
    end

    it "reports a book that is out as unavailable" do
      create(:loan, book: book)

      expect(JSON.parse(described_class.new(book.reload).serialize)["available"]).to be(false)
    end

    it "carries no borrowing history" do
      create(:loan, book: book)

      expect(JSON.parse(described_class.new(book.reload).serialize)).not_to have_key("loans")
    end

    it "renders a collection as an array" do
      create_list(:book, 3)

      rendered = JSON.parse(described_class.new(Book.order(:id)).serialize)

      expect(rendered.length).to eq(3)
    end
  end

  describe "the detail shape" do
    it "adds the borrowing history, each loan carrying its reader" do
      reader = create(:reader, name: "Ada Lovelace")
      loan = create(:loan, book: book, reader: reader,
                           borrowed_on: Date.new(2026, 9, 1),
                           due_on: Date.new(2026, 10, 1))
      expected = { "id" => book.id,
                   "title" => "Solaris",
                   "author" => "Stanisław Lem",
                   "serial_number" => "200003",
                   "available" => false,
                   "loans" => [ { "id" => loan.id,
                                  "borrowed_on" => "2026-09-01",
                                  "due_on" => "2026-10-01",
                                  "returned_on" => nil,
                                  "reader" => { "id" => reader.id,
                                                "name" => "Ada Lovelace",
                                                "email" => reader.email,
                                                "card_number" => reader.card_number } } ] }

      rendered = JSON.parse(described_class.new(book.reload, with_traits: :with_history).serialize)

      expect(rendered).to eq(expected)
    end

    it "renders an empty history for a book nobody has borrowed" do
      rendered = JSON.parse(described_class.new(book, with_traits: :with_history).serialize)

      expect(rendered["loans"]).to eq([])
    end
  end
end
