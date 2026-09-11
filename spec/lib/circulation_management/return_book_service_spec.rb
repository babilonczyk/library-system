require "rails_helper"

RSpec.describe CirculationManagement::ReturnBookService do
  let(:book) { create(:book) }

  it "takes the book back, stamping the date it came in" do
    loan = create(:loan, book: book, borrowed_on: Date.new(2026, 9, 7))

    result = described_class.call(book: book, on: Date.new(2026, 9, 20))

    aggregate_failures do
      expect(result[:loan]).to eq(loan)
      expect(loan.reload.returned_on).to eq(Date.new(2026, 9, 20))
      expect(loan).to be_closed
    end
  end

  it "returns as of today unless told otherwise" do
    create(:loan, book: book, borrowed_on: Date.new(2026, 9, 7))

    travel_to(Date.new(2026, 9, 11)) do
      expect(described_class.call(book: book)[:loan].returned_on).to eq(Date.new(2026, 9, 11))
    end
  end

  it "refuses a book that nobody has out" do
    result = described_class.call(book: book)

    expect(result).to eq(error: :book_not_borrowed)
  end

  it "refuses a book whose only loan already came back" do
    create(:loan, book: book, returned_on: Date.current)

    result = described_class.call(book: book)

    expect(result).to eq(error: :book_not_borrowed)
  end

  it "leaves the copy free to be lent again" do
    create(:loan, book: book, borrowed_on: Date.new(2026, 9, 7))
    described_class.call(book: book, on: Date.new(2026, 9, 20))

    lent_again = CirculationManagement::BorrowBookService.call(book: book.reload,
                                                               reader: create(:reader),
                                                               on: Date.new(2026, 9, 21))

    aggregate_failures do
      expect(lent_again[:loan]).to be_persisted
      expect(book.loans.count).to eq(2)
      expect(book.loans.open.count).to eq(1)
    end
  end

  it "returns the right copy when a reader has several books out" do
    reader = create(:reader)
    other = create(:book)
    create(:loan, book: book, reader: reader)
    untouched = create(:loan, book: other, reader: reader)

    described_class.call(book: book)

    aggregate_failures do
      expect(book.loans.open).to be_empty
      expect(untouched.reload.returned_on).to be_nil
    end
  end
end
