module CatalogManagement
  class WithdrawBookService < Core::BaseService
    def initialize(book:, at: Time.current)
      @book = book
      @at = at
    end

    # The lock is the point. Without it a borrow can land between the check and
    # the write, leaving a withdrawn book that someone is still holding.
    # CirculationManagement::BorrowBookService takes the same lock, which is
    # what makes the pair safe.
    def call
      @book.with_lock do
        return { error: :book_on_loan } if @book.loans.open.exists?

        @book.update!(withdrawn_at: @at)

        { book: @book }
      end
    end
  end
end
