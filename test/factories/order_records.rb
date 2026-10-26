FactoryBot.define do
  factory :order_record do
    merchant
    source { "manual" }
    ordered_on { Date.new(2026, 9, 15) }
  end
end
