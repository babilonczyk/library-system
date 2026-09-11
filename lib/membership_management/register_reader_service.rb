module MembershipManagement
  class RegisterReaderService < Core::BaseService
    def initialize(name: nil, email: nil, card_number: nil)
      @attributes = { name: name, email: email, card_number: card_number }
    end

    def call
      reader = Reader.new(@attributes)

      return { error: :validation_failed, errors: reader.errors } unless reader.save

      { reader: reader }
    rescue ActiveRecord::RecordNotUnique
      { error: :validation_failed, errors: duplicate_errors(reader) }
    end

    private
      # A reader has two unique indexes, and the exception does not say which one
      # was violated. Re-running validation does: the row we collided with is
      # committed by now, so the ordinary uniqueness check finds it and names the
      # right field. Parsing the database's message for an index name would tie
      # us to one adapter's wording.
      def duplicate_errors(reader)
        reader.validate
        reader.errors.add(:base, :taken) if reader.errors.empty?

        reader.errors
      end
  end
end
