module CirculationManagement
  class ReturnBookService < Core::BaseService
    def initialize(book:, on: Date.current)
      @book = book
      @on = on
    end

    # No combination of concurrent operations makes this one go wrong on its
    # own, so the lock is here for the invariant rather than for safety: every
    # change to a book's lending state serialises on the book row.
    def call
      @book.with_lock do
        loan = @book.loans.open.first
        return { error: :book_not_borrowed } if loan.nil?

        loan.update!(returned_on: @on)

        { loan: loan }
      end
    end
  end
end
