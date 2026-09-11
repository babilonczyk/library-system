class AddReminderStampsToLoans < ActiveRecord::Migration[8.1]
  def change
    # One stamp per reminder, because the two mails are independent: a loan
    # gets the advance warning and then the due-today mail, and each needs its
    # own mark to stay idempotent. Timestamps rather than flags, so a support
    # question about when a reader was told has an answer.
    add_column :loans, :upcoming_due_sent_at, :datetime
    add_column :loans, :due_today_sent_at, :datetime
  end
end
