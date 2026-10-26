FactoryBot.define do
  factory :order_inquiry_item do
    order_inquiry
    menu_item { nil }
    name { "雞腿飯" }
    quantity { 18 }
    unit_price { 90 }
  end
end
