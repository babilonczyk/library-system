require "rails_helper"

RSpec.describe LoanPolicy do
  describe ".due_on" do
    it "gives a book thirty days" do
      expect(described_class.due_on(Date.new(2026, 9, 1))).to eq(Date.new(2026, 10, 1))
    end

    it "counts calendar days, so it crosses a month boundary without help" do
      expect(described_class.due_on(Date.new(2026, 12, 20))).to eq(Date.new(2027, 1, 19))
    end
  end

  describe ".reminder_due_on" do
    it "gives the due date of the loans to remind about on a given day" do
      expect(described_class.reminder_due_on(Date.new(2026, 9, 11))).to eq(Date.new(2026, 9, 14))
    end
  end

  it "is self-consistent: a loan reminded on a day is due the lead time later" do
    due_on = described_class.due_on(Date.new(2026, 9, 1))
    remind_on = due_on - described_class::REMINDER_LEAD_DAYS

    expect(described_class.reminder_due_on(remind_on)).to eq(due_on)
  end

  it "states the numbers the domain runs on" do
    aggregate_failures do
      expect(described_class::LOAN_PERIOD_DAYS).to eq(30)
      expect(described_class::REMINDER_LEAD_DAYS).to eq(3)
    end
  end
end
