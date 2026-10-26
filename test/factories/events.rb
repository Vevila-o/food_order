FactoryBot.define do
  factory :event do
    held_on { Date.new(2026, 10, 27) } # 週二

    trait :with_headcount do
      transient do
        headcount { 18 }
      end

      after(:create) do |event, evaluator|
        create(:registration_snapshot, event: event, headcount: evaluator.headcount)
      end
    end
  end
end
