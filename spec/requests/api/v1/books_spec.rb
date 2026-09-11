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

      it "caps the page size, so no client can ask for the whole catalog" do
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

  describe "POST /api/v1/books" do
    let(:valid_attributes) { { title: "Solaris", author: "Stanisław Lem", serial_number: "200003" } }

    it "creates the book and answers 201 with it" do
      post "/api/v1/books", params: { book: valid_attributes }

      aggregate_failures do
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"]).to include(
          "title" => "Solaris", "serial_number" => "200003", "available" => true
        )
        expect(Book.count).to eq(1)
      end
    end

    it "points the Location header at the new book" do
      post "/api/v1/books", params: { book: valid_attributes }

      expect(response.headers["Location"]).to end_with("/api/v1/books/#{Book.first.id}")
    end

    it "answers 400 when the book parameter is missing entirely" do
      expected_errors = [ { "code" => "parameter_missing",
                            "detail" => "A required parameter is missing.",
                            "source" => "book" } ]

      post "/api/v1/books", params: { title: "Solaris" }

      aggregate_failures do
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq("errors" => expected_errors)
      end
    end

    it "answers 422 with one entry per missing field" do
      post "/api/v1/books", params: { book: { title: "Solaris" } }

      aggregate_failures do
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"].map { |error| error["source"] })
          .to contain_exactly("author", "serial_number")
        expect(response.parsed_body["errors"].map { |error| error["code"] }.uniq)
          .to eq([ "validation_failed" ])
      end
    end

    it "answers 422 for a serial number already in use" do
      create(:book, serial_number: "200003")
      expected_errors = [ { "code" => "validation_failed",
                            "detail" => "Serial number has already been taken",
                            "source" => "serial_number" } ]

      post "/api/v1/books", params: { book: valid_attributes }

      aggregate_failures do
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("errors" => expected_errors)
      end
    end

    it "ignores an attribute the client is not allowed to set" do
      post "/api/v1/books", params: { book: valid_attributes.merge(withdrawn_at: Time.current) }

      aggregate_failures do
        expect(response).to have_http_status(:created)
        expect(Book.first.withdrawn_at).to be_nil
      end
    end
  end

  describe "DELETE /api/v1/books/:id" do
    it "answers 204 with no body and takes the book out of the catalog" do
      book = create(:book)

      delete "/api/v1/books/#{book.id}"

      aggregate_failures do
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
        expect(book.reload).to be_withdrawn
      end
    end

    it "removes the book from the index and makes its detail 404" do
      book = create(:book)

      delete "/api/v1/books/#{book.id}"
      get "/api/v1/books"
      index = response.parsed_body["data"]
      get "/api/v1/books/#{book.id}"

      aggregate_failures do
        expect(index).to be_empty
        expect(response).to have_http_status(:not_found)
      end
    end

    it "keeps the borrowing history in the table" do
      book = create(:book)
      create(:loan, book: book, returned_on: Date.current)

      delete "/api/v1/books/#{book.id}"

      expect(book.loans.count).to eq(1)
    end

    it "answers 409 while the book is on loan" do
      book = create(:book, :borrowed)
      expected_errors = [ { "code" => "book_on_loan",
                            "detail" => "This book is on loan and cannot be withdrawn until it is returned." } ]

      delete "/api/v1/books/#{book.id}"

      aggregate_failures do
        expect(response).to have_http_status(:conflict)
        expect(response.parsed_body).to eq("errors" => expected_errors)
        expect(book.reload).not_to be_withdrawn
      end
    end

    it "answers 404 for a book that is already withdrawn" do
      book = create(:book, :withdrawn)

      delete "/api/v1/books/#{book.id}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/books/:id" do
    let(:book) { create(:book, title: "Solaris", author: "Stanisław Lem", serial_number: "200003") }

    it "returns the book with its borrowing history, each loan carrying its reader" do
      reader = create(:reader, name: "Ada Lovelace")
      create(:loan, book: book, reader: reader,
                    borrowed_on: Date.new(2026, 9, 1), due_on: Date.new(2026, 10, 1))

      get "/api/v1/books/#{book.id}"

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"]).to include("title" => "Solaris", "available" => false)
        expect(response.parsed_body["data"]["loans"].length).to eq(1)
        expect(response.parsed_body["data"]["loans"].first).to include(
          "borrowed_on" => "2026-09-01", "due_on" => "2026-10-01", "returned_on" => nil
        )
        expect(response.parsed_body["data"]["loans"].first["reader"]).to include("name" => "Ada Lovelace")
      end
    end

    it "lists the most recent borrowing first" do
      create(:loan, book: book, borrowed_on: Date.new(2026, 1, 1), due_on: Date.new(2026, 1, 31),
                    returned_on: Date.new(2026, 1, 10))
      create(:loan, book: book, borrowed_on: Date.new(2026, 5, 1), due_on: Date.new(2026, 5, 31),
                    returned_on: Date.new(2026, 5, 10))
      create(:loan, book: book, borrowed_on: Date.new(2026, 9, 1), due_on: Date.new(2026, 10, 1))

      get "/api/v1/books/#{book.id}"

      expect(response.parsed_body["data"]["loans"].map { |loan| loan["borrowed_on"] })
        .to eq([ "2026-09-01", "2026-05-01", "2026-01-01" ])
    end

    it "returns an empty history for a book nobody has borrowed" do
      get "/api/v1/books/#{book.id}"

      expect(response.parsed_body["data"]["loans"]).to eq([])
    end

    it "returns 404 for a withdrawn book, whose history survives in the table" do
      withdrawn = create(:book, :withdrawn)
      create(:loan, book: withdrawn)
      expected_errors = [ { "code" => "record_not_found",
                            "detail" => "The requested resource could not be found." } ]

      get "/api/v1/books/#{withdrawn.id}"

      aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body).to eq("errors" => expected_errors)
        expect(withdrawn.loans.count).to eq(1)
      end
    end

    it "returns 404 for a book that never existed" do
      get "/api/v1/books/0"

      expect(response).to have_http_status(:not_found)
    end

    it "issues the same number of queries however long the history is" do
      create(:loan, book: book, borrowed_on: Date.new(2026, 1, 1), due_on: Date.new(2026, 1, 31),
                    returned_on: Date.new(2026, 1, 10))
      baseline = count_queries { get "/api/v1/books/#{book.id}" }

      5.times do |n|
        create(:loan, book: book, borrowed_on: Date.new(2026, 2 + n, 1), due_on: Date.new(2026, 3 + n, 1),
                      returned_on: Date.new(2026, 2 + n, 10))
      end
      grown = count_queries { get "/api/v1/books/#{book.id}" }

      expect(grown).to eq(baseline)
    end
  end
end
