module CirculationManagement
  class DispatchRemindersService < Core::BaseService
    def initialize(on: Date.current)
      @on = on
    end

    # Returns how many of each reminder went out, which is what the sweep job
    # logs and the only interesting thing to assert on.
    def call
      upcoming_due = dispatch(Loan.due_for_upcoming_due_reminder(@on),
                              mail: :upcoming_due, stamp: :upcoming_due_sent_at)
      due_today = dispatch(Loan.due_for_due_today_reminder(@on),
                           mail: :due_today, stamp: :due_today_sent_at)

      { upcoming_due: upcoming_due, due_today: due_today }
    end

    private

    # The stamp is written before the mail is enqueued, and both sit in one
    # transaction. If the enqueue fails the stamp goes with it and tomorrow's
    # run picks the loan up again. The other order can leave a loan mailed but
    # unstamped, and the reader hears about the same book twice.
    #
    # One transaction per loan rather than one for the sweep: a single failure
    # should cost its own reminder, not every reminder after it.
    # No preload of the book and the reader. deliver_later hands Active Job a
    # global id and returns, so nothing here reads them; the mail is rendered
    # in the mailer job, one loan at a time. Measured: preloading them costs two
    # queries per sweep and saves none.
    def dispatch(loans, mail:, stamp:)
      sent = 0

      loans.find_each do |loan|
        loan.transaction do
          loan.update!(stamp => Time.current)
          ReminderMailer.with(loan: loan).public_send(mail).deliver_later
        end

        sent += 1
      end

      sent
    end
  end
end
