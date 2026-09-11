class Reader < ApplicationRecord
  CARD_NUMBER_FORMAT = /\A\d{6}\z/

  has_many :loans, dependent: :restrict_with_exception

  validates :name, presence: true
  # allow_blank on each format check, so a missing value reports only that it is
  # missing rather than that it is also malformed.
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true },
                    uniqueness: true
  # Uniqueness is case-insensitive without asking, because the column is citext.
  validates :card_number, presence: true,
                          format: { with: CARD_NUMBER_FORMAT, allow_blank: true },
                          uniqueness: true
end
