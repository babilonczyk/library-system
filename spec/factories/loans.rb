FactoryBot.define do
  # The default is an open loan, borrowed today and not yet due.
  factory :loan do
    book
    reader

    borrowed_on { Date.current }
    due_on { borrowed_on + 30 }

    trait :returned do
      returned_on { Date.current }
    end

    trait :overdue do
      borrowed_on { Date.current - 40 }
      due_on { Date.current - 10 }
    end
  end
end
