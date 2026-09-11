require "rails_helper"

RSpec.describe MembershipManagement::RegisterReaderService do
  it "registers the reader and hands them back" do
    result = described_class.call(name: "Ada Lovelace",
                                  email: "ada@example.com",
                                  card_number: "100001")

    aggregate_failures do
      expect(result[:reader]).to be_persisted
      expect(result[:reader]).to have_attributes(name: "Ada Lovelace", card_number: "100001")
      expect(Reader.count).to eq(1)
    end
  end

  it "refuses an attribute that was never supplied" do
    result = described_class.call(name: "Ada Lovelace")

    aggregate_failures do
      expect(result[:error]).to eq(:validation_failed)
      expect(result[:errors].attribute_names).to contain_exactly(:email, :card_number)
      expect(Reader.count).to eq(0)
    end
  end

  it "refuses an email that is not an address" do
    result = described_class.call(name: "Ada", email: "ada-at-example", card_number: "100001")

    aggregate_failures do
      expect(result[:error]).to eq(:validation_failed)
      expect(result[:errors].attribute_names).to contain_exactly(:email)
    end
  end

  it "refuses an email another reader already has" do
    create(:reader, email: "ada@example.com")

    result = described_class.call(name: "Ada", email: "ada@example.com", card_number: "100002")

    aggregate_failures do
      expect(result[:error]).to eq(:validation_failed)
      expect(result[:errors].full_messages).to eq([ "Email has already been taken" ])
    end
  end

  it "refuses an email differing from an existing one only in case" do
    create(:reader, email: "ada@example.com")

    result = described_class.call(name: "Ada", email: "ADA@example.com", card_number: "100002")

    expect(result[:errors].attribute_names).to contain_exactly(:email)
  end

  it "refuses a card number another reader already has" do
    create(:reader, card_number: "100001")

    result = described_class.call(name: "Grace", email: "grace@example.com", card_number: "100001")

    aggregate_failures do
      expect(result[:error]).to eq(:validation_failed)
      expect(result[:errors].full_messages).to eq([ "Card number has already been taken" ])
    end
  end
end
