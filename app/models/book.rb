class Book < ApplicationRecord
  SERIAL_NUMBER_FORMAT = /\A\d{6}\z/

  scope :kept, -> { where(withdrawn_at: nil) }

  validates :title, presence: true
  validates :author, presence: true
  validates :serial_number, presence: true,
                            format: { with: SERIAL_NUMBER_FORMAT },
                            uniqueness: true

  def withdrawn?
    withdrawn_at.present?
  end
end
