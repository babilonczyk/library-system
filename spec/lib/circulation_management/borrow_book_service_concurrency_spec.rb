require "rails_helper"

# Outside a transaction, because these races need one connection to commit
# where another can see it. Cleans up after itself for the same reason.
RSpec.describe CirculationManagement::BorrowBookService do
  self.use_transactional_tests = false

  after do
    Loan.delete_all
    Book.delete_all
    Reader.delete_all
  end

  def on_its_own_connection(&block)
    Thread.new { ActiveRecord::Base.connection_pool.with_connection(&block) }
  end

  it "lends a contested copy to exactly one reader" do
    book = create(:book)
    readers = create_list(:reader, 8)

    results = readers.map do |reader|
      on_its_own_connection { described_class.call(book: Book.find(book.id), reader: reader) }
    end.map(&:value)

    refused = results.select { |result| result[:error] }

    aggregate_failures do
      expect(results.count { |result| result[:loan] }).to eq(1)
      expect(refused.map { |result| result[:error] }.uniq).to eq([ :book_already_borrowed ])
      expect(Loan.where(book_id: book.id).count).to eq(1)
    end
  end

  it "never leaves a withdrawn book with a loan outstanding" do
    winners = 6.times.map do
      book = create(:book)
      reader = create(:reader)

      borrow = on_its_own_connection do
        described_class.call(book: Book.find(book.id), reader: reader)
      end
      withdraw = on_its_own_connection do
        CatalogManagement::WithdrawBookService.call(book: Book.find(book.id))
      end

      borrowed, withdrawn = borrow.value, withdraw.value
      book.reload

      aggregate_failures do
        # The outcome that must never happen: a book out of the catalog that
        # somebody is still holding.
        expect(book.withdrawn? && book.loans.open.exists?).to be(false)
        # Exactly one of the two operations succeeded.
        expect([ borrowed[:loan], withdrawn[:book] ].compact.length).to eq(1)
      end

      borrowed[:loan] ? :borrow : :withdraw
    end

    expect(winners).to all(be_in(%i[ borrow withdraw ]))
  end
end
