module Api
  module V1
    class BooksController < BaseController
      def index
        result = CatalogManagement::BookQueryService.call(available: params[:available])
        return render_error(result[:error]) if result[:error]

        books, meta = paginate(result[:books])

        render_data(BookSerializer.new(books).serializable_hash, meta: meta)
      end

      # A withdrawn book is gone as far as the API is concerned. Its history
      # survives in the table, but nothing serves it.
      def show
        book = Book.not_withdrawn.includes(loans: :reader).find(params[:id])

        render_data(BookSerializer.new(book, with_traits: :with_history).serializable_hash)
      end

      def create
        result = CatalogManagement::AddBookService.call(**book_params)
        return render_error(result[:error], errors: result[:errors]) if result[:error]

        book = result[:book]
        response.headers["Location"] = api_v1_book_url(book)

        render_data(BookSerializer.new(book).serializable_hash, status: :created)
      end

      # Soft delete. The row and its loans stay, the catalog loses the book.
      def destroy
        book = Book.not_withdrawn.find(params[:id])

        result = CatalogManagement::WithdrawBookService.call(book: book)
        return render_error(result[:error]) if result[:error]

        head :no_content
      end

      private
        def book_params
          params.expect(book: [ :title, :author, :serial_number ]).to_h.symbolize_keys
        end
    end
  end
end
