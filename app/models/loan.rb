class Loan < ApplicationRecord
  belongs_to :book
  belongs_to :reader

  scope :open, -> { where(returned_on: nil) }
  scope :closed, -> { where.not(returned_on: nil) }
  scope :overdue, ->(on = Date.current) { open.where(due_on: ...on) }

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
