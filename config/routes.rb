Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
    end
  end

  # Plain health check for load balancers and container healthchecks. Returns
  # 200 if the app boots with no exceptions, otherwise 500. Deliberately not in
  # the API envelope, so infrastructure does not have to parse JSON.
  get "up" => "rails/health#show", as: :rails_health_check
end
