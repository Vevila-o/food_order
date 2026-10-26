FactoryBot.define do
  factory :merchant do
    sequence(:name) { |n| "測試便當店 #{n}" }
    offers_food { true }
    offers_drink { false }

    trait :food_and_drink do
      offers_drink { true }
    end

    # 只賣飲料（桶裝、整箱）
    trait :drink_only do
      offers_food { false }
      offers_drink { true }
    end

    trait :with_contacts do
      line_id { "@rubyjam" }
      instagram { "rubyjam.lunch" }
      messenger_id { "rubyjam.page" }
      phone { "02-2345-6789" }
    end

    trait :delivers_at_19 do
      delivers_at_19 { "yes" }
    end

    trait :free_delivery do
      delivery_fee { 0 }
    end
  end
end
