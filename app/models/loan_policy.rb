module LoanPolicy
  LOAN_PERIOD_DAYS   = 30
  REMINDER_LEAD_DAYS = 3

  # When a book borrowed on this date is due back.
  def self.due_on(borrowed_on)
    borrowed_on + LOAN_PERIOD_DAYS
  end

  # The due date a loan must carry for its reminder to go out on `on`.
  # Expressed this way round so the sweep can query the indexed due_on column
  # rather than compute a date per row.
  def self.reminder_due_on(on)
    on + REMINDER_LEAD_DAYS
  end
end
