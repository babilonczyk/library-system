module Api
  module V1
    # The book itself identifies the loan being closed: only one can be open.
    class ReturnsController < BaseController
      def create
        book = Book.not_withdrawn.find(params[:book_id])

        result = CirculationManagement::ReturnBookService.call(book: book)
        return render_error(result[:error]) if result[:error]

        render_data(LoanSerializer.new(result[:loan]).serializable_hash)
      end
    end
  end
end
