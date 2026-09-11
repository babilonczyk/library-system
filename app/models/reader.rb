class Reader < ApplicationRecord
  CARD_NUMBER_FORMAT = /\A\d{6}\z/

  validates :name, presence: true
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: true
  # Uniqueness is case-insensitive without asking, because the column is citext.
  validates :card_number, presence: true,
                          format: { with: CARD_NUMBER_FORMAT },
                          uniqueness: true
end
