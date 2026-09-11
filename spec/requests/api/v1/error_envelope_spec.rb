require "rails_helper"

# No endpoint can fail yet, so the handlers are exercised through a controller
# and routes that exist only for the duration of these examples. Nothing
# test-only ships in the application.
RSpec.describe "API error envelope" do
  around do |example|
    with_routing do |routes|
      routes.draw do
        namespace :api do
          namespace :v1 do
            get "probes/missing", to: "probes#missing"
            get "probes/invalid", to: "probes#invalid"
            get "probes/required", to: "probes#required"
          end
        end
      end

      example.run
    end
  end

  before do
    stub_const("ProbeRecord", Class.new do
      include ActiveModel::Model

      attr_accessor :title

      validates :title, presence: true

      def self.name
        "ProbeRecord"
      end
    end)

    stub_const("Api::V1::ProbesController", Class.new(Api::V1::BaseController) do
      def missing
        raise ActiveRecord::RecordNotFound
      end

      def invalid
        record = ProbeRecord.new
        record.validate

        raise ActiveRecord::RecordInvalid.new(record)
      end

      def required
        params.require(:book)
      end
    end)
  end

  it "answers a missing record with 404 and a translated detail" do
    expected_errors = [ { "code" => "record_not_found",
                          "detail" => "The requested resource could not be found." } ]

    get "/api/v1/probes/missing"

    aggregate_failures do
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("errors" => expected_errors)
    end
  end

  it "answers an invalid record with 422 and one entry per offending field" do
    expected_errors = [ { "code" => "validation_failed",
                          "detail" => "Title can't be blank",
                          "source" => "title" } ]

    get "/api/v1/probes/invalid"

    aggregate_failures do
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("errors" => expected_errors)
    end
  end

  it "answers a missing parameter with 400, naming the parameter" do
    expected_errors = [ { "code" => "parameter_missing",
                          "detail" => "A required parameter is missing.",
                          "source" => "book" } ]

    get "/api/v1/probes/required"

    aggregate_failures do
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to eq("errors" => expected_errors)
    end
  end
end
