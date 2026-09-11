require "rails_helper"

# Proves the whole chain is wired: the application boots, the database is
# reachable, and the configuration we set is the configuration in force.
# CI depends on this spec meaning something, since it is the only one that
# exists when the pipeline is stood up.
RSpec.describe "Application environment" do
  it "boots in the test environment" do
    expect(Rails.env).to be_test
  end

  it "holds a live connection to the test database" do
    aggregate_failures do
      expect(ActiveRecord::Base.connection).to be_active
      expect(ActiveRecord::Base.connection_db_config.database).to eq("library_system_test")
    end
  end

  # Guards the mistake that this exact line was added to catch: preparing the
  # test database with a task that also runs seeds. Without it, development
  # sample data turns up as twenty-odd unrelated failures elsewhere.
  it "starts from an empty database" do
    aggregate_failures do
      expect(Book.count).to eq(0)
      expect(Reader.count).to eq(0)
      expect(Loan.count).to eq(0)
    end
  end

  it "runs in UTC" do
    expect(Time.zone.name).to eq("UTC")
  end

  it "serializes through Alba with the Oj backend" do
    expect(Alba.backend).to eq(:oj_rails)
  end
end
