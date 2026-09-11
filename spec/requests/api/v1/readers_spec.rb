require "rails_helper"

RSpec.describe "Api::V1::Readers" do
  describe "GET /api/v1/readers" do
    it "lists readers by name, in the same envelope as every other list" do
      create(:reader, name: "Grace Hopper")
      create(:reader, name: "Ada Lovelace")
      expected_meta = { "page" => 1, "limit" => 20, "count" => 2, "pages" => 1 }

      get "/api/v1/readers"

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"].map { |reader| reader["name"] })
          .to eq([ "Ada Lovelace", "Grace Hopper" ])
        expect(response.parsed_body["meta"]).to eq(expected_meta)
      end
    end

    it "paginates like the books index" do
      create_list(:reader, 25)

      get "/api/v1/readers", params: { page: 2, limit: 10 }

      aggregate_failures do
        expect(response.parsed_body["data"].length).to eq(10)
        expect(response.parsed_body["meta"]).to include("page" => 2, "limit" => 10, "pages" => 3)
      end
    end
  end

  describe "POST /api/v1/readers" do
    let(:valid_attributes) do
      { name: "Ada Lovelace", email: "ada@example.com", card_number: "100001" }
    end

    it "registers the reader and answers 201" do
      post "/api/v1/readers", params: { reader: valid_attributes }, as: :json

      aggregate_failures do
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"]).to eq(
          "id" => Reader.first.id,
          "name" => "Ada Lovelace",
          "email" => "ada@example.com",
          "card_number" => "100001"
        )
      end
    end

    it "answers 400 when the reader parameter is missing entirely" do
      post "/api/v1/readers", params: { name: "Ada" }, as: :json

      aggregate_failures do
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["errors"].first).to include("code" => "parameter_missing",
                                                               "source" => "reader")
      end
    end

    it "answers 422 with one entry per missing field" do
      post "/api/v1/readers", params: { reader: { name: "Ada" } }, as: :json

      aggregate_failures do
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"].map { |error| error["source"] })
          .to contain_exactly("email", "card_number")
      end
    end

    it "answers 422 for an email already registered" do
      create(:reader, email: "ada@example.com")
      expected_errors = [ { "code" => "validation_failed",
                            "detail" => "Email has already been taken",
                            "source" => "email" } ]

      post "/api/v1/readers", params: { reader: valid_attributes.merge(card_number: "100002") }, as: :json

      aggregate_failures do
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("errors" => expected_errors)
      end
    end

    it "answers 422 for a card number already issued" do
      create(:reader, card_number: "100001")
      expected_errors = [ { "code" => "validation_failed",
                            "detail" => "Card number has already been taken",
                            "source" => "card_number" } ]

      post "/api/v1/readers", params: { reader: valid_attributes.merge(email: "other@example.com") }, as: :json

      aggregate_failures do
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("errors" => expected_errors)
      end
    end
  end
end
