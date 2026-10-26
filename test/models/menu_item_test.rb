require "test_helper"

class MenuItemTest < ActiveSupport::TestCase
  setup { travel_to Time.zone.local(2026, 10, 27, 12, 0) }

  test "120 天內的菜單是新鮮的，剛好 120 天仍有效" do
    assert build(:menu_item, menu_date: Date.current).fresh?
    assert build(:menu_item, menu_date: Date.current - 120).fresh?
  end

  test "第 121 天起視為過期" do
    item = build(:menu_item, menu_date: Date.current - 121)

    assert item.stale?
    assert_not item.fresh?
    assert_not item.orderable?
    assert_equal :stale, item.freshness
  end

  test "日期不明的菜單不可進訂單詢問產生器" do
    item = build(:menu_item, :date_unknown)

    assert item.date_unknown?
    assert_not item.orderable?
    assert_equal :unknown, item.freshness
  end

  test "fresh / stale / date_unknown scopes 互不重疊" do
    fresh = create(:menu_item)
    stale = create(:menu_item, :stale)
    unknown = create(:menu_item, :date_unknown)

    assert_equal [ fresh ], MenuItem.fresh.to_a
    assert_equal [ stale ], MenuItem.stale.to_a
    assert_equal [ unknown ], MenuItem.date_unknown.to_a
  end

  test "菜單日期不可晚於今天" do
    assert_not build(:menu_item, menu_date: Date.current + 1).valid?
  end

  test "價格必須是不為負的整數" do
    assert_not build(:menu_item, price: -1).valid?
    assert_not build(:menu_item, price: 9.5).valid?
    assert build(:menu_item, price: 0).valid?
  end

  test "category 只接受 food / drink" do
    assert_not build(:menu_item, category: "dessert").valid?
    assert build(:menu_item, :drink).valid?
  end

  test "整箱、整桶可以記單位與可供幾人，並算出每人單價" do
    item = build(:menu_item, :drink, name: "鋁箔包茶（一箱）", price: 360, unit: "箱", servings: 24)

    assert_equal 15, item.price_per_serving
  end

  test "沒填可供幾人時沒有每人單價，且份數必須大於 0" do
    assert_nil build(:menu_item).price_per_serving
    assert_not build(:menu_item, servings: 0).valid?
  end
end
