FactoryBot.define do
  factory :order_inquiry do
    event
    merchant
    headcount_at_creation { 18 }
    subtotal { 1500 }
    delivery_fee { 0 }
    total { 1500 }
    status { "draft" }

    # 外送費未知：預計金額也未知（NULL）
    trait :fee_unknown do
      delivery_fee { nil }
      total { nil }
    end
  end
end
