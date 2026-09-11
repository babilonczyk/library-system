module Api
  module V1
    # Borrowing a book creates a borrowing, so the action is create. A separate
    # controller from returns, because `return` is a Ruby keyword and cannot be
    # an action name.
    class BorrowingsController < BaseController
      def create
        book = Book.not_withdrawn.find(params[:book_id])
        reader = Reader.find_by!(card_number: borrowing_params[:card_number])

        result = CirculationManagement::BorrowBookService.call(book: book, reader: reader)
        return render_error(result[:error]) if result[:error]

        render_data(LoanSerializer.new(result[:loan]).serializable_hash, status: :created)
      end

      private
        def borrowing_params
          params.expect(borrowing: [ :card_number ])
        end
    end
  end
end
