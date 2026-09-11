namespace :db do
  desc "Drop, recreate, migrate and reseed the database in one command"
  task reseed: :environment do
    abort "Refusing to reseed in #{Rails.env}." if Rails.env.production?

    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:seed"].invoke
  end
end
