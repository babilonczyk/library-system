FactoryBot.define do
  factory :book do
    title { Faker::Book.title }
    author { Faker::Book.author }
    sequence(:serial_number) { |n| format("%06d", n) }

    trait :withdrawn do
      withdrawn_at { Time.current }
    end
  end
end
