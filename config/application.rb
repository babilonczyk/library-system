require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module LibrarySystem
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # Stated rather than implied. The loan lifecycle uses Date columns, so the
    # zone decides one thing: what Date.current returns when the reminder
    # sweep runs. UTC keeps that boundary identical here, in CI and in Docker.
    config.time_zone = "UTC"

    # Rails looks in test/mailers/previews by default, and this project has no
    # test directory. Set here rather than in development.rb so a spec can
    # render the previews and catch one that has stopped working.
    config.action_mailer.preview_paths = [ Rails.root.join("spec/mailers/previews").to_s ]
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Background work runs on Sidekiq everywhere except the test environment,
    # which keeps the adapter that lets specs assert on enqueued jobs.
    config.active_job.queue_adapter = :sidekiq

    # Cookies and a session, added back for one reason: the Sidekiq dashboard
    # is a Rack app that needs a session for its CSRF protection. An API-only
    # app has neither by default, and nothing else here uses them.
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore, key: "_library_system_session"
  end
end
