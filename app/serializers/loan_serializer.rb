class LoanSerializer
  include Alba::Resource

  attributes :id, :borrowed_on, :due_on, :returned_on

  # Who held the book. Off by default, because a reader's own loan list has no
  # use for repeating the reader on every entry.
  trait :with_reader do
    one :reader, resource: ReaderSerializer
  end
end
