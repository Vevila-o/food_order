FactoryBot.define do
  factory :merchant_source do
    merchant
    platform { "manual" }
    url { "https://example.com/menu" }
  end
end
