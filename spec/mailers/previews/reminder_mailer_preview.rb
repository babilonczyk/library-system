# Visible at /rails/mailers in development. Uses whatever the seeds put in the
# database rather than inventing records, so the previews show real data and
# break loudly if the mailer stops matching the model.
class ReminderMailerPreview < ActionMailer::Preview
  def upcoming_due
    ReminderMailer.with(loan: a_loan).upcoming_due
  end

  def due_today
    ReminderMailer.with(loan: a_loan).due_today
  end

  private
    def a_loan
      Loan.open.includes(:book, :reader).first || Loan.includes(:book, :reader).first
    end
end
