require "rails_helper"

RSpec.describe "Api::V1::Returns" do
  describe "POST /api/v1/books/:book_id/return" do
    let(:book) { create(:book) }

    it "takes the book back and answers 200 with the closed loan" do
      loan = create(:loan, book: book, borrowed_on: Date.new(2026, 9, 7))

      travel_to(Date.new(2026, 9, 20)) do
        post "/api/v1/books/#{book.id}/return"
      end

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"]).to include("id" => loan.id,
                                                        "returned_on" => "2026-09-20")
        expect(loan.reload).to be_closed
      end
    end

    it "frees the copy to be lent again" do
      create(:loan, book: book)
      create(:reader, card_number: "100001")

      post "/api/v1/books/#{book.id}/return"
      post "/api/v1/books/#{book.id}/borrow", params: { borrowing: { card_number: "100001" } }, as: :json

      aggregate_failures do
        expect(response).to have_http_status(:created)
        expect(book.loans.count).to eq(2)
      end
    end

    it "answers 409 when nobody has it out" do
      expected_errors = [ { "code" => "book_not_borrowed",
                            "detail" => "This book is not currently on loan." } ]

      post "/api/v1/books/#{book.id}/return"

      aggregate_failures do
        expect(response).to have_http_status(:conflict)
        expect(response.parsed_body).to eq("errors" => expected_errors)
      end
    end

    it "answers 404 for a book that never existed" do
      post "/api/v1/books/0/return"

      expect(response).to have_http_status(:not_found)
    end

    it "answers 404 for a withdrawn book" do
      withdrawn = create(:book, :withdrawn)

      post "/api/v1/books/#{withdrawn.id}/return"

      expect(response).to have_http_status(:not_found)
    end
  end
end
