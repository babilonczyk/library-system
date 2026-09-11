module Api
  module V1
    # Fixes the HTTP contract once, so no controller invents its own shape.
    #
    # Success: { "data": ..., "meta": { ... } }
    # Failure: { "errors": [ { "code": ..., "detail": ..., "source": ... } ] }
    #
    # `code` is the symbol a service returned, rendered as a string. It is the
    # machine-readable part. `detail` is looked up from the locale file by that
    # same symbol, which is what lets the domain layer return bare symbols and
    # never hold a sentence of English.
    class BaseController < ApplicationController
      include Pagy::Method

      # The cap is what stops a client asking for a whole table at once.
      MAX_LIMIT = 100

      # Grows as services introduce new refusals. Anything unmapped answers 422,
      # which is the right default for "understood, but refused".
      ERROR_STATUSES = {
        record_not_found: :not_found,
        parameter_missing: :bad_request,
        invalid_availability_filter: :bad_request,
        book_on_loan: :conflict,
        validation_failed: :unprocessable_content
      }.freeze

      DEFAULT_ERROR_STATUS = :unprocessable_content

      rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
      rescue_from ActionController::ParameterMissing, with: :render_parameter_missing

      private
        # Every list endpoint answers with the same meta object.
        def paginate(scope)
          page, records = pagy(scope, max_limit: MAX_LIMIT)

          [ records, { page: page.page, limit: page.limit, count: page.count, pages: page.pages } ]
        end

        def render_data(data, meta: nil, status: :ok)
          body = { data: data }
          body[:meta] = meta if meta

          render json: body, status: status
        end

        # The single way a refusal reaches the client. Record errors render one
        # entry per offending field, each naming the field in `source`.
        def render_error(code, source: nil, errors: nil)
          entries =
            if errors
              errors.map { |error| error_object(code, source: error.attribute, detail: error.full_message) }
            else
              [ error_object(code, source: source) ]
            end

          render json: { errors: entries }, status: status_for(code)
        end

        def error_object(code, source: nil, detail: nil)
          object = { code: code.to_s, detail: detail || detail_for(code) }
          object[:source] = source.to_s if source

          object
        end

        def detail_for(code)
          I18n.t(code, scope: "api.errors", default: I18n.t("api.errors.unknown"))
        end

        def status_for(code)
          ERROR_STATUSES.fetch(code, DEFAULT_ERROR_STATUS)
        end

        def render_record_not_found
          render_error(:record_not_found)
        end

        def render_record_invalid(exception)
          render_error(:validation_failed, errors: exception.record.errors)
        end

        def render_parameter_missing(exception)
          render_error(:parameter_missing, source: exception.param)
        end
    end
  end
end
