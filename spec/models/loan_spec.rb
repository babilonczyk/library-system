require "rails_helper"

RSpec.describe Loan do
  subject(:loan) { build(:loan) }

  describe "associations" do
    it { is_expected.to belong_to(:book) }
    it { is_expected.to belong_to(:reader) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:borrowed_on) }
    it { is_expected.to validate_presence_of(:due_on) }

    it "refuses a due date earlier than the borrow date" do
      loan = build(:loan, borrowed_on: Date.new(2026, 9, 11), due_on: Date.new(2026, 9, 10))

      aggregate_failures do
        expect(loan).to be_invalid
        expect(loan.errors[:due_on]).to be_present
      end
    end

    it "refuses a return date earlier than the borrow date" do
      loan = build(:loan, borrowed_on: Date.new(2026, 9, 11), returned_on: Date.new(2026, 9, 10))

      aggregate_failures do
        expect(loan).to be_invalid
        expect(loan.errors[:returned_on]).to be_present
      end
    end

    it "accepts a book returned on the day it was borrowed" do
      loan = build(:loan, borrowed_on: Date.new(2026, 9, 11), returned_on: Date.new(2026, 9, 11))

      expect(loan).to be_valid
    end
  end

  describe "scopes" do
    around { |example| travel_to(Date.new(2026, 9, 11)) { example.run } }

    it ".open returns loans that have not come back" do
      still_out = create(:loan)
      create(:loan, :returned)

      expect(described_class.open).to contain_exactly(still_out)
    end

    it ".closed returns loans that have" do
      create(:loan)
      returned = create(:loan, :returned)

      expect(described_class.closed).to contain_exactly(returned)
    end

    it ".overdue returns open loans whose due date has passed" do
      overdue = create(:loan, :overdue)
      create(:loan)
      create(:loan, :overdue, returned_on: Date.current)

      expect(described_class.overdue).to contain_exactly(overdue)
    end

    it ".overdue treats a loan due today as not yet overdue" do
      create(:loan, borrowed_on: Date.new(2026, 8, 12), due_on: Date.new(2026, 9, 11))

      expect(described_class.overdue).to be_empty
    end
  end

  describe "#overdue?" do
    around { |example| travel_to(Date.new(2026, 9, 11)) { example.run } }

    it "is true for an open loan past its due date" do
      expect(build(:loan, :overdue)).to be_overdue
    end

    it "is false on the due date itself" do
      expect(build(:loan, borrowed_on: Date.new(2026, 8, 12), due_on: Date.new(2026, 9, 11)))
        .not_to be_overdue
    end

    it "is false once the book is back, however late" do
      expect(build(:loan, :overdue, returned_on: Date.current)).not_to be_overdue
    end
  end

  describe "database constraints" do
    it "refuses a second active loan on the same book" do
      first = create(:loan)

      expect { create(:loan, book: first.book) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows a new loan once the previous one has been returned" do
      first = create(:loan, :returned)

      expect { create(:loan, book: first.book) }.not_to raise_error
    end

    it "allows the same reader two active loans on different books" do
      first = create(:loan)

      expect { create(:loan, reader: first.reader) }.not_to raise_error
    end

    it "refuses a due date earlier than the borrow date" do
      persisted = create(:loan)

      expect { persisted.update_column(:due_on, persisted.borrowed_on - 1) }
        .to raise_error(ActiveRecord::StatementInvalid, /loans_due_on_is_not_before_borrowed_on/)
    end

    it "refuses a return date earlier than the borrow date" do
      persisted = create(:loan)

      expect { persisted.update_column(:returned_on, persisted.borrowed_on - 1) }
        .to raise_error(ActiveRecord::StatementInvalid, /loans_returned_on_is_not_before_borrowed_on/)
    end
  end
end
