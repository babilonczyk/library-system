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

  describe ".due_for_upcoming_due_reminder" do
    around { |example| travel_to(Date.new(2026, 9, 11)) { example.run } }

    subject(:due_for_reminder) { described_class.due_for_upcoming_due_reminder }

    let(:book) { create(:book) }
    let(:returned_on) { nil }
    let(:upcoming_due_sent_at) { nil }
    # Three days from the frozen date, so this loan is the one to remind about.
    let(:due_on) { Date.new(2026, 9, 14) }
    let!(:loan) do
      create(:loan,
             book: book,
             borrowed_on: Date.new(2026, 8, 15),
             due_on: due_on,
             returned_on: returned_on,
             upcoming_due_sent_at: upcoming_due_sent_at)
    end

    it "returns an open loan due in three days that has not been reminded yet" do
      expect(due_for_reminder).to contain_exactly(loan)
    end

    it "reads the date it is given rather than today" do
      aggregate_failures do
        expect(described_class.due_for_upcoming_due_reminder(Date.new(2026, 9, 10))).to be_empty
        expect(described_class.due_for_upcoming_due_reminder(Date.new(2026, 9, 11)))
          .to contain_exactly(loan)
      end
    end

    context "when the reminder has already gone out" do
      let(:upcoming_due_sent_at) { Time.current }

      it { is_expected.to be_empty }
    end

    context "when the loan is due on another day" do
      let(:due_on) { Date.new(2026, 9, 15) }

      it { is_expected.to be_empty }
    end

    context "when the book is already back" do
      let(:returned_on) { Date.current }

      it { is_expected.to be_empty }
    end

    context "when the book has been withdrawn" do
      let(:book) { create(:book, :withdrawn) }

      it { is_expected.to be_empty }
    end
  end

  describe ".due_for_due_today_reminder" do
    around { |example| travel_to(Date.new(2026, 9, 11)) { example.run } }

    subject(:due_for_reminder) { described_class.due_for_due_today_reminder }

    let(:book) { create(:book) }
    let(:returned_on) { nil }
    let(:due_today_sent_at) { nil }
    let(:upcoming_due_sent_at) { nil }
    let!(:loan) do
      create(:loan,
             book: book,
             borrowed_on: Date.new(2026, 8, 12),
             due_on: Date.new(2026, 9, 11),
             returned_on: returned_on,
             due_today_sent_at: due_today_sent_at,
             upcoming_due_sent_at: upcoming_due_sent_at)
    end

    it "returns an open loan due today that has not been reminded yet" do
      expect(due_for_reminder).to contain_exactly(loan)
    end

    context "when the reminder has already gone out" do
      let(:due_today_sent_at) { Time.current }

      it { is_expected.to be_empty }
    end

    context "when the advance reminder has gone out" do
      let(:upcoming_due_sent_at) { Date.new(2026, 9, 8) }

      it "still returns the loan, since the two reminders are tracked apart" do
        expect(due_for_reminder).to contain_exactly(loan)
      end
    end

    context "when the book is already back" do
      let(:returned_on) { Date.current }

      it { is_expected.to be_empty }
    end

    context "when the book has been withdrawn" do
      let(:book) { create(:book, :withdrawn) }

      it { is_expected.to be_empty }
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
