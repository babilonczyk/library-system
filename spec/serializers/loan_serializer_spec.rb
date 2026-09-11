require "rails_helper"

RSpec.describe LoanSerializer do
  let(:loan) do
    create(:loan, borrowed_on: Date.new(2026, 9, 1),
                  due_on: Date.new(2026, 10, 1),
                  returned_on: Date.new(2026, 9, 20))
  end

  it "renders the three dates and nothing else" do
    expected = { "id" => loan.id,
                 "borrowed_on" => "2026-09-01",
                 "due_on" => "2026-10-01",
                 "returned_on" => "2026-09-20" }

    expect(JSON.parse(described_class.new(loan).serialize)).to eq(expected)
  end

  it "renders a null return date while the book is still out" do
    still_out = create(:loan, borrowed_on: Date.new(2026, 9, 1), due_on: Date.new(2026, 10, 1))

    expect(JSON.parse(described_class.new(still_out).serialize)["returned_on"]).to be_nil
  end

  it "adds the reader only when asked" do
    expected = { "id" => loan.reader.id,
                 "name" => loan.reader.name,
                 "email" => loan.reader.email,
                 "card_number" => loan.reader.card_number }

    rendered = JSON.parse(described_class.new(loan, with_traits: :with_reader).serialize)

    expect(rendered["reader"]).to eq(expected)
  end
end
