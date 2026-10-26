FactoryBot.define do
  factory :registration_snapshot do
    event
    headcount { 18 }
    source { "manual" }

    trait :webhook do
      source { "webhook" }
      sequence(:kktix_order_id) { |n| "order-#{n}" }
      kktix_event_type { "order_paid" }
    end
  end
end
