require "rails_helper"

RSpec.describe Reader do
  subject(:reader) { build(:reader) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:card_number) }
    # Card numbers are digits only, so there is no case to be sensitive to.
    it { is_expected.to validate_uniqueness_of(:card_number).ignoring_case_sensitivity }

    it "accepts an address-shaped email and rejects one that is not" do
      aggregate_failures do
        expect(reader).to allow_value("ada@example.com").for(:email)
        expect(reader).not_to allow_value("ada-at-example").for(:email)
      end
    end

    it "accepts exactly six digits, leading zeros included" do
      expect(reader).to allow_value("000123").for(:card_number)
    end

    it "rejects a card number that is not exactly six digits" do
      aggregate_failures do
        expect(reader).not_to allow_value("12345").for(:card_number)
        expect(reader).not_to allow_value("1234567").for(:card_number)
        expect(reader).not_to allow_value("12345a").for(:card_number)
      end
    end
  end

  describe "database constraints" do
    it "refuses a card number that is not six digits" do
      persisted = create(:reader)

      expect { persisted.update_column(:card_number, "12") }
        .to raise_error(ActiveRecord::StatementInvalid, /readers_card_number_is_six_digits/)
    end

    it "refuses an email differing from an existing one only in case" do
      create(:reader, email: "ada@example.com")
      duplicate = build(:reader, email: "ADA@example.com")

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
