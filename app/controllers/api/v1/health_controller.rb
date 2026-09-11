module Api
  module V1
    # Answers in the success envelope, so the contract is exercised by something
    # from the moment the namespace exists. Infrastructure checks should use the
    # plain /up endpoint instead.
    class HealthController < BaseController
      def show
        render_data({ status: "ok" })
      end
    end
  end
end
