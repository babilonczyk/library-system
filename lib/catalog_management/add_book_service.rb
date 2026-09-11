module CatalogManagement
  class AddBookService < Core::BaseService
    # Missing attributes default to nil so the model, not the signature, decides
    # what a valid book is. Strong parameters simply omit anything absent.
    def initialize(title: nil, author: nil, serial_number: nil)
      @attributes = { title: title, author: author, serial_number: serial_number }
    end

    def call
      book = Book.new(@attributes)

      return { error: :validation_failed, errors: book.errors } unless book.save

      { book: book }
    rescue ActiveRecord::RecordNotUnique
      # Lost a race between the uniqueness check and the insert. The unique
      # index is the real guard, so answer exactly as the check would have.
      book.errors.add(:serial_number, :taken)

      { error: :validation_failed, errors: book.errors }
    end
  end
end
