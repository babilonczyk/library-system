require "rails_helper"

# The only spec that runs outside a transaction, because the race it reproduces
# needs one connection to commit where another can see it. It cleans up after
# itself for the same reason.
RSpec.describe CatalogManagement::AddBookService do
  self.use_transactional_tests = false

  let(:serial) { "999001" }

  after { Book.where(serial_number: "999001").delete_all }

  it "lets exactly one of many simultaneous requests win, and refuses the rest cleanly" do
    attempts = 8

    results = attempts.times.map do |n|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          described_class.call(title: "Race #{n}", author: "Anon", serial_number: serial)
        end
      end
    end.map(&:value)

    created = results.count { |result| result[:book] }
    refused = results.select { |result| result[:error] }

    aggregate_failures do
      expect(created).to eq(1)
      expect(refused.length).to eq(attempts - 1)
      expect(refused.map { |result| result[:error] }.uniq).to eq([ :validation_failed ])
      expect(refused.flat_map { |result| result[:errors].full_messages }.uniq)
        .to eq([ "Serial number has already been taken" ])
      expect(Book.where(serial_number: serial).count).to eq(1)
    end
  end
end
