require "rails_helper"

# The document is written by hand, so the thing to guard is drift. These
# examples compare it against the application's own route table in both
# directions: an endpoint missing from the document fails, and so does a
# documented endpoint that no longer exists.
RSpec.describe "openapi.yaml", type: :request do
  subject(:document) { YAML.load_file(Rails.root.join("openapi.yaml")) }

  # "/api/v1/books/:id" as the route table spells it, "/api/v1/books/{id}" as
  # OpenAPI does.
  let(:routed) do
    Rails.application.routes.routes.filter_map do |route|
      path = route.path.spec.to_s.sub("(.:format)", "")
      next unless path.start_with?("/api/")

      verb = route.verb.downcase
      "#{verb} #{path.gsub(/:(\w+)/) { "{#{Regexp.last_match(1)}}" }}"
    end
  end

  let(:documented) do
    document["paths"].flat_map do |path, operations|
      operations.keys.map { |verb| "#{verb} #{path}" }
    end
  end

  it "documents every endpoint the application serves" do
    expect(routed - documented).to be_empty
  end

  it "documents nothing the application no longer serves" do
    expect(documented - routed).to be_empty
  end

  it "gives every operation a summary and a success response" do
    missing = document["paths"].flat_map do |path, operations|
      operations.filter_map do |verb, operation|
        success = operation["responses"].keys.find { |status| status.to_s.start_with?("2") }

        "#{verb} #{path}" unless operation["summary"] && success
      end
    end

    expect(missing).to be_empty
  end

  # Paths matching while the fields have moved on is the likelier drift, so the
  # schemas are compared against what the serializers actually produce.
  describe "the documented shapes" do
    let(:schemas) { document["components"]["schemas"] }

    def properties(name)
      schemas.fetch(name)["properties"].keys
    end

    it "describes a book as the API serves it" do
      book = create(:book)

      expect(BookSerializer.new(book).serializable_hash.keys.map(&:to_s))
        .to match_array(properties("Book"))
    end

    it "describes a reader as the API serves it" do
      reader = create(:reader)

      expect(ReaderSerializer.new(reader).serializable_hash.keys.map(&:to_s))
        .to match_array(properties("Reader"))
    end

    it "describes a loan as the API serves it" do
      loan = create(:loan)

      expect(LoanSerializer.new(loan).serializable_hash.keys.map(&:to_s))
        .to match_array(properties("Loan"))
    end

    it "describes the borrowing history as the API serves it" do
      book = create(:book, :borrowed)

      serialized = BookSerializer.new(book, with_traits: :with_history).serializable_hash

      aggregate_failures do
        expect(serialized.keys.map(&:to_s)).to match_array(properties("Book") + [ "loans" ])
        expect(serialized["loans"].first.keys.map(&:to_s))
          .to match_array(properties("Loan") + [ "reader" ])
      end
    end

    it "describes the pagination meta object as the API serves it" do
      create(:book)

      get "/api/v1/books"

      expect(response.parsed_body["meta"].keys).to match_array(properties("PageMeta"))
    end
  end

  # Every code the base controller knows how to answer with should be findable
  # in the document, or a client has no way to learn it exists.
  it "mentions every error code the API can return" do
    codes = Api::V1::BaseController::ERROR_STATUSES.keys.map(&:to_s)

    expect(codes.reject { |code| document.to_s.include?(code) }).to be_empty
  end
end
