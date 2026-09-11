require "rails_helper"

RSpec.describe "Api::V1::Borrowings" do
  describe "POST /api/v1/books/:book_id/borrow" do
    let(:book) { create(:book) }
    let(:reader) { create(:reader, card_number: "100001") }

    it "lends the book and answers 201 with the loan" do
      reader

      travel_to(Date.new(2026, 9, 11)) do
        post "/api/v1/books/#{book.id}/borrow", params: { borrowing: { card_number: "100001" } }
      end

      aggregate_failures do
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"]).to include("borrowed_on" => "2026-09-11",
                                                        "due_on" => "2026-10-11",
                                                        "returned_on" => nil)
        expect(book.loans.open.first.reader).to eq(reader)
      end
    end

    it "reports the book as unavailable afterwards" do
      reader
      post "/api/v1/books/#{book.id}/borrow", params: { borrowing: { card_number: "100001" } }

      get "/api/v1/books/#{book.id}"

      expect(response.parsed_body["data"]["available"]).to be(false)
    end

    it "answers 409 when somebody already has it" do
      reader
      create(:loan, book: book)
      expected_errors = [ { "code" => "book_already_borrowed",
                            "detail" => "This book is already on loan." } ]

      post "/api/v1/books/#{book.id}/borrow", params: { borrowing: { card_number: "100001" } }

      aggregate_failures do
        expect(response).to have_http_status(:conflict)
        expect(response.parsed_body).to eq("errors" => expected_errors)
      end
    end

    it "answers 404 for a card number nobody holds" do
      post "/api/v1/books/#{book.id}/borrow", params: { borrowing: { card_number: "999999" } }

      aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(book.loans).to be_empty
      end
    end

    it "answers 404 for a book that never existed" do
      reader

      post "/api/v1/books/0/borrow", params: { borrowing: { card_number: "100001" } }

      expect(response).to have_http_status(:not_found)
    end

    it "answers 404 for a withdrawn book" do
      reader
      withdrawn = create(:book, :withdrawn)

      post "/api/v1/books/#{withdrawn.id}/borrow", params: { borrowing: { card_number: "100001" } }

      aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(withdrawn.loans).to be_empty
      end
    end

    it "answers 400 when the borrowing parameter is missing" do
      post "/api/v1/books/#{book.id}/borrow", params: { card_number: "100001" }

      aggregate_failures do
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["errors"].first).to include("code" => "parameter_missing",
                                                               "source" => "borrowing")
      end
    end
  end
end
