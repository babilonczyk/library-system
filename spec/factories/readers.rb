FactoryBot.define do
  factory :reader do
    # Faker only for the value nothing asserts on. Email and card number are
    # sequences, because both have to be unique and a test should not be able
    # to fail on a collision.
    name { Faker::Name.name }
    sequence(:email) { |n| "reader#{n}@example.com" }
    sequence(:card_number) { |n| format("%06d", n) }
  end
end
