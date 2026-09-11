require "rails_helper"

RSpec.describe "Api::V1::Books" do
  describe "GET /api/v1/books" do
    it "answers in the success envelope, with pagination in the meta object" do
      create(:book, title: "Dune", author: "Frank Herbert", serial_number: "200001")
      expected_meta = { "page" => 1, "limit" => 20, "count" => 1, "pages" => 1 }

      get "/api/v1/books"

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["meta"]).to eq(expected_meta)
        expect(response.parsed_body["data"].first).to include("title" => "Dune", "available" => true)
      end
    end

    it "carries no borrowing history in the list" do
      create(:book, :borrowed)

      get "/api/v1/books"

      expect(response.parsed_body["data"].first).not_to have_key("loans")
    end

    it "leaves withdrawn books out" do
      create(:book, :withdrawn)

      get "/api/v1/books"

      aggregate_failures do
        expect(response.parsed_body["data"]).to be_empty
        expect(response.parsed_body["meta"]["count"]).to eq(0)
      end
    end

    describe "the available filter" do
      before do
        create(:book, title: "Free")
        create(:book, :borrowed, title: "Taken")
      end

      it "returns only free books when true" do
        get "/api/v1/books", params: { available: "true" }

        expect(response.parsed_body["data"].map { |book| book["title"] }).to eq([ "Free" ])
      end

      it "returns only books on loan when false" do
        get "/api/v1/books", params: { available: "false" }

        expect(response.parsed_body["data"].map { |book| book["title"] }).to eq([ "Taken" ])
      end

      it "refuses a value it does not recognise" do
        expected_errors = [ { "code" => "invalid_availability_filter",
                              "detail" => "The available filter accepts only true or false." } ]

        get "/api/v1/books", params: { available: "banana" }

        aggregate_failures do
          expect(response).to have_http_status(:bad_request)
          expect(response.parsed_body).to eq("errors" => expected_errors)
        end
      end
    end

    describe "pagination" do
      before { create_list(:book, 25) }

      it "serves the requested page" do
        get "/api/v1/books", params: { page: 2 }

        aggregate_failures do
          expect(response.parsed_body["data"].length).to eq(5)
          expect(response.parsed_body["meta"]).to eq("page" => 2, "limit" => 20, "count" => 25, "pages" => 2)
        end
      end

      it "honours a requested page size" do
        get "/api/v1/books", params: { limit: 10 }

        aggregate_failures do
          expect(response.parsed_body["data"].length).to eq(10)
          expect(response.parsed_body["meta"]).to include("limit" => 10, "pages" => 3)
        end
      end

      it "caps the page size, so no client can ask for the whole catalogue" do
        get "/api/v1/books", params: { limit: 5_000 }

        expect(response.parsed_body["meta"]["limit"]).to eq(100)
      end
    end

    it "issues the same number of queries however many books there are" do
      create_list(:book, 3).each { |book| create(:loan, book: book) }
      baseline = count_queries { get "/api/v1/books" }

      create_list(:book, 10).each { |book| create(:loan, book: book) }
      grown = count_queries { get "/api/v1/books" }

      expect(grown).to eq(baseline)
    end
  end
end
