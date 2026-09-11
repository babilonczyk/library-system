module Api
  module V1
    class BooksController < BaseController
      include Pagy::Method

      # The cap is what stops a client asking for the whole catalog at once.
      MAX_LIMIT = 100

      def index
        result = CatalogManagement::BookQueryService.call(available: params[:available])
        return render_error(result[:error]) if result[:error]

        page, books = pagy(result[:books], max_limit: MAX_LIMIT)

        render_data(BookSerializer.new(books).serializable_hash, meta: pagination(page))
      end

      # A withdrawn book is gone as far as the API is concerned. Its history
      # survives in the table, but nothing serves it.
      def show
        book = Book.not_withdrawn.includes(loans: :reader).find(params[:id])

        render_data(BookSerializer.new(book, with_traits: :with_history).serializable_hash)
      end

      private
        def pagination(page)
          { page: page.page, limit: page.limit, count: page.count, pages: page.pages }
        end
    end
  end
end
