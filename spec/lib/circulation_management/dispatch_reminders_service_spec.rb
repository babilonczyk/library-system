require "rails_helper"

RSpec.describe CirculationManagement::DispatchRemindersService do
  # Every example runs on this date, so the due dates below are readable as
  # "three days from now" and "today" without arithmetic.
  around { |example| travel_to(Time.utc(2026, 9, 11, 6)) { example.run } }

  describe "the reminder three days before a book is due" do
    let(:book) { create(:book) }
    let!(:loan) do
      create(:loan, book: book, borrowed_on: Date.new(2026, 8, 15), due_on: Date.new(2026, 9, 14))
    end

    it "mails the reader" do
      expect { described_class.call }
        .to have_enqueued_mail(ReminderMailer, :upcoming_due).with(params: { loan: loan }, args: [])
    end

    it "reports what it sent" do
      expect(described_class.call).to eq(upcoming_due: 1, due_today: 0)
    end

    it "stamps the loan with the time it went out" do
      described_class.call

      expect(loan.reload.upcoming_due_sent_at).to eq(Time.utc(2026, 9, 11, 6))
    end

    it "sends nothing on a second run the same day" do
      described_class.call

      aggregate_failures do
        expect { described_class.call }.not_to have_enqueued_mail(ReminderMailer, :upcoming_due)
        expect(described_class.call).to eq(upcoming_due: 0, due_today: 0)
      end
    end

    context "when the book is already back" do
      let!(:loan) do
        create(:loan, book: book, borrowed_on: Date.new(2026, 8, 15),
                      due_on: Date.new(2026, 9, 14), returned_on: Date.new(2026, 9, 10))
      end

      it "leaves the reader alone" do
        expect { described_class.call }.not_to have_enqueued_mail(ReminderMailer, :upcoming_due)
      end
    end

    context "when the book has been withdrawn" do
      let(:book) { create(:book, :withdrawn) }

      it "leaves the reader alone" do
        expect { described_class.call }.not_to have_enqueued_mail(ReminderMailer, :upcoming_due)
      end
    end
  end

  describe "the reminder on the day a book is due" do
    let(:book) { create(:book) }
    let!(:loan) do
      create(:loan, book: book, borrowed_on: Date.new(2026, 8, 12), due_on: Date.new(2026, 9, 11))
    end

    it "mails the reader" do
      expect { described_class.call }
        .to have_enqueued_mail(ReminderMailer, :due_today).with(params: { loan: loan }, args: [])
    end

    it "reports what it sent" do
      expect(described_class.call).to eq(upcoming_due: 0, due_today: 1)
    end

    it "stamps the loan with the time it went out" do
      described_class.call

      expect(loan.reload.due_today_sent_at).to eq(Time.utc(2026, 9, 11, 6))
    end

    it "sends nothing on a second run the same day" do
      described_class.call

      expect { described_class.call }.not_to have_enqueued_mail(ReminderMailer, :due_today)
    end
  end

  describe "a loan over its whole life" do
    let!(:loan) do
      create(:loan, borrowed_on: Date.new(2026, 8, 15), due_on: Date.new(2026, 9, 14))
    end

    it "gets the advance reminder, then the due-today one three days later" do
      expect { described_class.call }
        .to have_enqueued_mail(ReminderMailer, :upcoming_due).with(params: { loan: loan }, args: [])

      # The sweep three days on. Passed as an argument rather than travelled to,
      # because the clock is already frozen for this example.
      expect { described_class.call(on: Date.new(2026, 9, 14)) }
        .to have_enqueued_mail(ReminderMailer, :due_today).with(params: { loan: loan }, args: [])
    end
  end

  describe "the date it sweeps" do
    let!(:loan) do
      create(:loan, borrowed_on: Date.new(2026, 8, 16), due_on: Date.new(2026, 9, 15))
    end

    it "reads the date it is given rather than today" do
      aggregate_failures do
        expect(described_class.call).to eq(upcoming_due: 0, due_today: 0)
        expect(described_class.call(on: Date.new(2026, 9, 12))).to eq(upcoming_due: 1, due_today: 0)
      end
    end
  end

  describe "the queries it issues" do
    it "costs one query per reminder and nothing more" do
      create(:loan, borrowed_on: Date.new(2026, 8, 15), due_on: Date.new(2026, 9, 14))
      one_reminder = count_queries { described_class.call }

      create_list(:loan, 3, borrowed_on: Date.new(2026, 8, 15), due_on: Date.new(2026, 9, 14))
      three_reminders = count_queries { described_class.call }

      # Two more reminders, two more updates. Anything the service read per
      # loan would show up here as well.
      expect(three_reminders - one_reminder).to eq(2)
    end
  end
end
