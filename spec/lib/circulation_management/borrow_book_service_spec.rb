require "rails_helper"

RSpec.describe CirculationManagement::BorrowBookService do
  let(:book) { create(:book) }
  let(:reader) { create(:reader) }

  it "lends the book, dating the loan from the policy" do
    result = described_class.call(book: book, reader: reader, on: Date.new(2026, 9, 7))

    aggregate_failures do
      expect(result[:loan]).to be_persisted
      expect(result[:loan]).to have_attributes(book: book,
                                               reader: reader,
                                               borrowed_on: Date.new(2026, 9, 7),
                                               due_on: Date.new(2026, 10, 7),
                                               returned_on: nil)
    end
  end

  it "borrows from today unless told otherwise" do
    travel_to(Date.new(2026, 9, 11)) do
      result = described_class.call(book: book, reader: reader)

      expect(result[:loan].borrowed_on).to eq(Date.new(2026, 9, 11))
    end
  end

  it "refuses a book that is already out, whoever asks" do
    described_class.call(book: book, reader: reader)

    result = described_class.call(book: book, reader: create(:reader))

    aggregate_failures do
      expect(result).to eq(error: :book_already_borrowed)
      expect(book.loans.count).to eq(1)
    end
  end

  it "refuses a withdrawn book" do
    withdrawn = create(:book, :withdrawn)

    result = described_class.call(book: withdrawn, reader: reader)

    aggregate_failures do
      expect(result).to eq(error: :book_withdrawn)
      expect(withdrawn.loans).to be_empty
    end
  end

  it "lends the same copy again once it has come back" do
    first = described_class.call(book: book, reader: reader)[:loan]
    first.update!(returned_on: Date.current)

    result = described_class.call(book: book, reader: create(:reader))

    aggregate_failures do
      expect(result[:loan]).to be_persisted
      expect(book.loans.count).to eq(2)
    end
  end

  it "lets one reader hold two different books at once" do
    described_class.call(book: book, reader: reader)

    result = described_class.call(book: create(:book), reader: reader)

    expect(result[:loan]).to be_persisted
  end
end
