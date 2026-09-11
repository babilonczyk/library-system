require "rails_helper"

# The dashboard itself needs a running Redis, which CI does not have, so this
# checks the two things that actually break: the mount, and the middleware an
# API-only app leaves out. Rendering it is verified by hand against a real
# Sidekiq process.
RSpec.describe "the Sidekiq dashboard" do
  it "is mounted" do
    mounted = Rails.application.routes.routes.find { |route| route.path.spec.to_s == "/sidekiq" }

    expect(mounted&.app&.app).to eq(Sidekiq::Web)
  end

  it "has the cookies and session middleware the dashboard needs for CSRF" do
    middleware = Rails.application.config.middleware.map(&:name)

    aggregate_failures do
      expect(middleware).to include("ActionDispatch::Cookies")
      expect(middleware).to include("ActionDispatch::Session::CookieStore")
    end
  end
end
