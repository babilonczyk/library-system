require "rails_helper"

RSpec.describe CirculationManagement::Jobs::ReminderSweepJob do
  around { |example| travel_to(Time.utc(2026, 9, 11, 6)) { example.run } }

  let!(:due_in_three_days) do
    create(:loan, borrowed_on: Date.new(2026, 8, 15), due_on: Date.new(2026, 9, 14))
  end
  let!(:due_today) do
    create(:loan, borrowed_on: Date.new(2026, 8, 12), due_on: Date.new(2026, 9, 11))
  end

  it "runs on its own queue, so a backlog elsewhere cannot delay a reminder" do
    expect { described_class.perform_later }
      .to have_enqueued_job(described_class).on_queue("reminders")
  end

  it "sends both reminders" do
    expect(described_class.perform_now).to eq(upcoming_due: 1, due_today: 1)
  end

  it "mails the readers" do
    aggregate_failures do
      expect { described_class.perform_now }
        .to have_enqueued_mail(ReminderMailer, :upcoming_due)
        .with(params: { loan: due_in_three_days }, args: [])
      expect { described_class.perform_now }
        .not_to have_enqueued_mail(ReminderMailer, :upcoming_due)
    end
  end

  it "sweeps the date it is given, so a missed day can be caught up" do
    expect(described_class.perform_now(Date.new(2026, 9, 14)))
      .to eq(upcoming_due: 0, due_today: 1)
  end

  it "takes the date back from a string, which is how Active Job returns it" do
    expect(described_class.perform_now("2026-09-14"))
      .to eq(upcoming_due: 0, due_today: 1)
  end
end
