require "sidekiq/web"
# Adds the Cron tab to the dashboard, which is where the daily schedule and its
# last run are visible.
require "sidekiq/cron/web"

Rails.application.routes.draw do
  # No authentication. Anyone who can reach the port can retry or kill a job.
  # Stated in the README as a known gap rather than solved with a login the
  # brief never asked for.
  mount Sidekiq::Web => "/sidekiq"

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"

      resources :books, only: %i[ index show create destroy ]
      resources :readers, only: %i[ index create ]

      post "books/:book_id/borrow", to: "borrowings#create"
      post "books/:book_id/return", to: "returns#create"
    end
  end

  # The contract, browsable at /api-docs. That page is static, in public, and
  # fetches this.
  get "openapi.yaml" => "api_docs#show"

  # Plain health check for load balancers and container healthchecks. Returns
  # 200 if the app boots with no exceptions, otherwise 500. Deliberately not in
  # the API envelope, so infrastructure does not have to parse JSON.
  get "up" => "rails/health#show", as: :rails_health_check
end
