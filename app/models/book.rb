class Book < ApplicationRecord
  SERIAL_NUMBER_FORMAT = /\A\d{6}\z/

  # Newest borrowing first, sorted by the database. The tie-break on id matters
  # because two loans can share a borrow date.
  #
  # Never destroyed with the book: withdrawal is soft precisely so that a
  # book's borrowing history survives it.
  has_many :loans, -> { order(borrowed_on: :desc, id: :desc) },
           dependent: :restrict_with_exception
  has_one :active_loan, -> { open }, class_name: "Loan"

  scope :withdrawn,     -> { where.not(withdrawn_at: nil) }
  scope :not_withdrawn, -> { where(withdrawn_at: nil) }

  validates :title, presence: true
  validates :author, presence: true
  validates :serial_number, presence: true,
                            format: { with: SERIAL_NUMBER_FORMAT },
                            uniqueness: true

  def withdrawn?
    withdrawn_at.present?
  end

  # Status is derived from the loans, never stored. One source of truth serves
  # both the listing and the history.
  def borrowed?
    active_loan.present?
  end

  def available?
    !withdrawn? && !borrowed?
  end
end
