class Loan < ApplicationRecord
  belongs_to :book
  belongs_to :reader

  scope :open, -> { where(returned_on: nil) }
  scope :closed, -> { where.not(returned_on: nil) }
  scope :overdue, ->(on = Date.current) { open.where(due_on: ...on) }

  # A loan worth mailing about. The book has to still be in the catalogue: a
  # withdrawn book means the copy is gone, and chasing a reader for it would be
  # noise.
  scope :mailable, -> { open.joins(:book).merge(Book.not_withdrawn) }

  # Who to mail on a given date. Both read due_on, which is indexed.
  scope :due_for_upcoming_due_reminder, ->(on = Date.current) {
    mailable.where(upcoming_due_sent_at: nil, due_on: LoanPolicy.reminder_due_on(on))
  }
  scope :due_for_due_today_reminder, ->(on = Date.current) {
    mailable.where(due_today_sent_at: nil, due_on: on)
  }

  validates :borrowed_on, presence: true
  validates :due_on, presence: true

  validates :due_on, comparison: { greater_than_or_equal_to: :borrowed_on },
                     if: -> { borrowed_on.present? && due_on.present? }
  validates :returned_on, comparison: { greater_than_or_equal_to: :borrowed_on },
                          if: -> { borrowed_on.present? && returned_on.present? }

  def open?
    returned_on.nil?
  end

  def closed?
    !open?
  end

  # A loan due today is not yet overdue.
  def overdue?(on = Date.current)
    open? && due_on < on
  end
end
