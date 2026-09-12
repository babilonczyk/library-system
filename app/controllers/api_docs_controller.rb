# Serves the OpenAPI document to the Swagger UI page in public/api-docs.
#
# The document lives at the repository root rather than in public, so it reads
# as part of the project rather than as an asset, and so it is the first thing
# found by anyone browsing the repository.
class ApiDocsController < ApplicationController
  def show
    send_file Rails.root.join("openapi.yaml"),
              type: "application/yaml",
              disposition: "inline"
  end
end
