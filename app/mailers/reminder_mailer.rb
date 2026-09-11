class ReminderMailer < ApplicationMailer
  # Parameterized rather than positional, so the sweep can enqueue these with
  # deliver_later and Active Job can serialise the loan by global id.
  def upcoming_due
    @loan = params[:loan]

    mail to: @loan.reader.email,
         subject: "#{@loan.book.title} is due back on #{@loan.due_on.to_fs(:long)}"
  end

  def due_today
    @loan = params[:loan]

    mail to: @loan.reader.email,
         subject: "#{@loan.book.title} is due back today"
  end
end
