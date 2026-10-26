FactoryBot.define do
  factory :menu_item do
    merchant
    sequence(:name) { |n| "雞腿飯 #{n}" }
    category { "food" }
    price { 90 }
    menu_date { Date.current }

    trait :drink do
      category { "drink" }
      name { "紅茶" }
      price { 30 }
    end

    # 菜單日期超過 120 天
    trait :stale do
      menu_date { Date.current - (MenuItem::FRESH_DAYS + 1) }
    end

    trait :date_unknown do
      menu_date { nil }
    end
  end
end
