module Api
  module V1
    class ReadersController < BaseController
      def index
        readers, meta = paginate(Reader.order(:name, :id))

        render_data(ReaderSerializer.new(readers).serializable_hash, meta: meta)
      end

      # No Location header: readers have no detail endpoint to point at, and
      # the created reader is already in the body.
      def create
        result = MembershipManagement::RegisterReaderService.call(**reader_params)
        return render_error(result[:error], errors: result[:errors]) if result[:error]

        render_data(ReaderSerializer.new(result[:reader]).serializable_hash, status: :created)
      end

      private
        def reader_params
          params.expect(reader: [ :name, :email, :card_number ]).to_h.symbolize_keys
        end
    end
  end
end
