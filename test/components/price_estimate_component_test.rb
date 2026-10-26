require "test_helper"

class PriceEstimateComponentTest < ViewComponent::TestCase
  def render_for(merchant)
    render_inline(PriceEstimateComponent.new(merchant: merchant))
  end

  test "手填範圍" do
    render_for(build(:merchant, price_per_person_min: 80, price_per_person_max: 100))

    assert_text "每人 NT$80–100"
  end

  test "手填單一價格" do
    render_for(build(:merchant, price_per_person_min: 90))

    assert_text "每人 NT$90"
  end

  test "沒手填：依菜單推算並註明" do
    merchant = create(:merchant, :food_and_drink)
    create(:menu_item, merchant: merchant, price: 95)
    create(:menu_item, :drink, merchant: merchant, price: 35)

    render_for(merchant.reload)

    assert_text "每人約 NT$130（依菜單）"
  end

  test "只賣飲料：單價 / 單位，不顯示每人" do
    merchant = create(:merchant, :drink_only)
    create(:menu_item, :drink, merchant: merchant, price: 1280, unit: "桶", servings: 20)

    render_for(merchant.reload)

    assert_text "NT$1,280 / 桶"
    assert_no_text "每人"
  end

  test "算不出來：估價未填（較淡的字）" do
    render_for(build(:merchant))

    assert_selector "span.opacity-70", text: "估價未填"
  end
end
