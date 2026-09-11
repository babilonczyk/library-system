require "rails_helper"

RSpec.describe "Api::V1::Health" do
  describe "GET /api/v1/health" do
    it "answers in the success envelope" do
      expected_body = { "data" => { "status" => "ok" } }

      get "/api/v1/health"

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(expected_body)
      end
    end
  end
end
