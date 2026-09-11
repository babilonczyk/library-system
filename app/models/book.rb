class Book < ApplicationRecord
  SERIAL_NUMBER_FORMAT = /\A\d{6}\z/

  # Loans are never destroyed with their book. Withdrawal is soft precisely so
  # that a book's borrowing history survives it.
  has_many :loans, dependent: :restrict_with_exception
  has_one :active_loan, -> { open }, class_name: "Loan"

  scope :kept, -> { where(withdrawn_at: nil) }

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
