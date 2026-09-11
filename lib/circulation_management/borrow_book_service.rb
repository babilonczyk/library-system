module CirculationManagement
  class BorrowBookService < Core::BaseService
    def initialize(book:, reader:, on: Date.current)
      @book = book
      @reader = reader
      @on = on
    end

    # No "is this book already out" query anywhere. The partial unique index on
    # open loans answers that by refusing the insert, so the everyday case and
    # the simultaneous case take the same path and the rare one cannot rot.
    #
    # The lock is the other half of D2's withdrawal: it stops a withdrawal
    # landing between reading withdrawn? and writing the loan.
    def call
      @book.with_lock do
        return { error: :book_withdrawn } if @book.withdrawn?

        { loan: @book.loans.create!(reader: @reader,
                                    borrowed_on: @on,
                                    due_on: LoanPolicy.due_on(@on)) }
      end
    rescue ActiveRecord::RecordNotUnique
      { error: :book_already_borrowed }
    end
  end
end
