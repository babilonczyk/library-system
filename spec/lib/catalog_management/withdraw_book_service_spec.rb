require "rails_helper"

RSpec.describe CatalogManagement::WithdrawBookService do
  it "withdraws a book nobody has out" do
    book = create(:book)

    result = described_class.call(book: book, at: Time.utc(2026, 9, 11, 12))

    aggregate_failures do
      expect(result[:book]).to eq(book)
      expect(book.reload.withdrawn_at).to eq(Time.utc(2026, 9, 11, 12))
      expect(book).to be_withdrawn
    end
  end

  it "refuses a book that is currently on loan" do
    book = create(:book, :borrowed)

    result = described_class.call(book: book)

    aggregate_failures do
      expect(result).to eq(error: :book_on_loan)
      expect(book.reload.withdrawn_at).to be_nil
    end
  end

  it "withdraws a book whose loans have all come back" do
    book = create(:book)
    create(:loan, book: book, returned_on: Date.current)

    result = described_class.call(book: book)

    aggregate_failures do
      expect(result[:book]).to eq(book)
      expect(book.reload).to be_withdrawn
    end
  end

  it "leaves the borrowing history untouched" do
    book = create(:book)
    create(:loan, book: book, returned_on: Date.current)

    expect { described_class.call(book: book) }.not_to change(Loan, :count)
  end
end
