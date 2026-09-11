module CatalogManagement
  # Builds the relation behind the books index. Withdrawn books never appear,
  # whatever the filter says.
  class BookQueryService < Core::BaseService
    AVAILABILITY = { "true" => true, "false" => false }.freeze

    def initialize(available: nil)
      @available = available
    end

    def call
      return { error: :invalid_availability_filter } unless recognised_filter?

      { books: filtered }
    end

    private
      def recognised_filter?
        @available.nil? || AVAILABILITY.key?(@available.to_s)
      end

      # A subquery rather than a join, so it composes with the preload above
      # instead of fighting it.
      def filtered
        return kept if @available.nil?

        AVAILABILITY.fetch(@available.to_s) ? kept.where.not(id: on_loan) : kept.where(id: on_loan)
      end

      def kept
        Book.kept.includes(:active_loan).order(:title, :id)
      end

      def on_loan
        Loan.open.select(:book_id)
      end
  end
end
