module Api
  module V1
    class BooksController < BaseController
      include Pagy::Method

      # The cap is what stops a client asking for the whole catalogue at once.
      MAX_LIMIT = 100

      def index
        result = CatalogManagement::BookQueryService.call(available: params[:available])
        return render_error(result[:error]) if result[:error]

        page, books = pagy(result[:books], max_limit: MAX_LIMIT)

        render_data(BookSerializer.new(books).serializable_hash, meta: pagination(page))
      end

      private
        def pagination(page)
          { page: page.page, limit: page.limit, count: page.count, pages: page.pages }
        end
    end
  end
end
