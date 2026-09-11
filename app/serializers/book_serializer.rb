class BookSerializer
  include Alba::Resource

  attributes :id, :title, :author, :serial_number

  # Derived from the loans, never stored. Withdrawn books are the third state
  # and are never serialised: they leave the index and 404 on show.
  attribute :available do |book|
    book.available?
  end

  # The detail shape. Opt-in, so the index cannot serialise every loan and
  # reader by forgetting an option. Ordering belongs to whoever loads the
  # loans, not here.
  trait :with_history do
    many :loans, resource: LoanSerializer, with_traits: :with_reader
  end
end
