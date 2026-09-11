require "rails_helper"

# Runs outside a transaction, because the race needs one connection to commit
# where another can see it. Cleans up after itself for the same reason.
RSpec.describe MembershipManagement::RegisterReaderService do
  self.use_transactional_tests = false

  after { Reader.where("email LIKE 'race%' OR card_number LIKE '99%'").delete_all }

  def race(attempts:, &attributes_for)
    attempts.times.map do |n|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          described_class.call(**attributes_for.call(n))
        end
      end
    end.map(&:value)
  end

  it "lets one registration win a contested email, and names the email on the rest" do
    results = race(attempts: 8) do |n|
      { name: "Racer #{n}", email: "race@example.com", card_number: format("99%04d", n) }
    end

    refused = results.select { |result| result[:error] }

    aggregate_failures do
      expect(results.count { |result| result[:reader] }).to eq(1)
      expect(refused.length).to eq(7)
      expect(refused.flat_map { |result| result[:errors].attribute_names }.uniq).to eq([ :email ])
      expect(Reader.where(email: "race@example.com").count).to eq(1)
    end
  end

  it "lets one registration win a contested card number, and names the card number on the rest" do
    results = race(attempts: 8) do |n|
      { name: "Racer #{n}", email: "race#{n}@example.com", card_number: "990000" }
    end

    refused = results.select { |result| result[:error] }

    aggregate_failures do
      expect(results.count { |result| result[:reader] }).to eq(1)
      expect(refused.flat_map { |result| result[:errors].attribute_names }.uniq).to eq([ :card_number ])
      expect(Reader.where(card_number: "990000").count).to eq(1)
    end
  end
end
