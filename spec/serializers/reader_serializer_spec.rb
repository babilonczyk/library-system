require "rails_helper"

RSpec.describe ReaderSerializer do
  it "renders the reader's identity and contact details" do
    reader = create(:reader, name: "Ada Lovelace",
                             email: "ada@example.com",
                             card_number: "100001")
    expected = { "id" => reader.id,
                 "name" => "Ada Lovelace",
                 "email" => "ada@example.com",
                 "card_number" => "100001" }

    expect(JSON.parse(described_class.new(reader).serialize)).to eq(expected)
  end
end
