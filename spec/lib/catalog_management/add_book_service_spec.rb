require "rails_helper"

RSpec.describe CatalogManagement::AddBookService do
  it "adds the book and hands it back" do
    result = described_class.call(title: "Solaris", author: "Stanisław Lem", serial_number: "200003")

    aggregate_failures do
      expect(result[:book]).to be_persisted
      expect(result[:book]).to have_attributes(title: "Solaris", author: "Stanisław Lem")
      expect(Book.count).to eq(1)
    end
  end

  it "refuses an attribute that was never supplied" do
    result = described_class.call(title: "Solaris")

    aggregate_failures do
      expect(result[:error]).to eq(:validation_failed)
      expect(result[:errors].attribute_names).to contain_exactly(:author, :serial_number)
      expect(Book.count).to eq(0)
    end
  end

  it "refuses a serial number that is not six digits" do
    result = described_class.call(title: "Solaris", author: "Lem", serial_number: "12")

    aggregate_failures do
      expect(result[:error]).to eq(:validation_failed)
      expect(result[:errors].attribute_names).to contain_exactly(:serial_number)
    end
  end

  it "refuses a serial number another book already has" do
    create(:book, serial_number: "200003")

    result = described_class.call(title: "Solaris", author: "Lem", serial_number: "200003")

    aggregate_failures do
      expect(result[:error]).to eq(:validation_failed)
      expect(result[:errors].full_messages).to include("Serial number has already been taken")
    end
  end

  it "refuses a serial number held by a withdrawn book" do
    create(:book, :withdrawn, serial_number: "200003")

    result = described_class.call(title: "Solaris", author: "Lem", serial_number: "200003")

    expect(result[:error]).to eq(:validation_failed)
  end
end
