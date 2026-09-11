require "rails_helper"

RSpec.describe Book do
  subject(:book) { build(:book) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:author) }
    it { is_expected.to validate_presence_of(:serial_number) }
    # Serial numbers are digits only, so there is no case to be sensitive to.
    it { is_expected.to validate_uniqueness_of(:serial_number).ignoring_case_sensitivity }

    it "accepts exactly six digits, leading zeros included" do
      expect(book).to allow_value("000123").for(:serial_number)
    end

    it "rejects a serial number that is not exactly six digits" do
      aggregate_failures do
        expect(book).not_to allow_value("12345").for(:serial_number)
        expect(book).not_to allow_value("1234567").for(:serial_number)
        expect(book).not_to allow_value("12345a").for(:serial_number)
      end
    end
  end

  describe ".kept" do
    it "returns books that have not been withdrawn" do
      kept = create(:book)
      create(:book, :withdrawn)

      expect(described_class.kept).to contain_exactly(kept)
    end
  end

  describe "#withdrawn?" do
    it "is false while the book is in the catalogue" do
      expect(build(:book)).not_to be_withdrawn
    end

    it "is true once it has been withdrawn" do
      expect(build(:book, :withdrawn)).to be_withdrawn
    end
  end

  describe "database constraints" do
    it "refuses a serial number that is not six digits" do
      persisted = create(:book)

      expect { persisted.update_column(:serial_number, "12") }
        .to raise_error(ActiveRecord::StatementInvalid, /books_serial_number_is_six_digits/)
    end

    it "refuses a serial number already taken by a withdrawn book" do
      create(:book, :withdrawn, serial_number: "424242")
      duplicate = build(:book, serial_number: "424242")

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
