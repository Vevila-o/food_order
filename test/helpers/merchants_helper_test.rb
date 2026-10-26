require "test_helper"

class MerchantsHelperTest < ActionView::TestCase
  test "店家類型標籤" do
    assert_equal "餐＋飲", kind_label(build(:merchant, :food_and_drink))
    assert_equal "只有餐", kind_label(build(:merchant))
    assert_equal "僅飲料", kind_label(build(:merchant, :drink_only))
  end

  test "餐＋飲標籤用 accent 色票" do
    assert_equal "badge-accent", kind_badge_class(build(:merchant, :food_and_drink))
    assert_equal "badge-secondary", kind_badge_class(build(:merchant, :drink_only))
  end

  test "菜單新鮮度文字與樣式" do
    assert_equal "菜單有效", freshness_label(build(:menu_item))
    assert_equal "菜單可能過期", freshness_label(build(:menu_item, :stale))
    assert_equal "日期不明", freshness_label(build(:menu_item, :date_unknown))
    assert_equal "badge-warning", freshness_badge_class(build(:menu_item, :stale))
    assert_equal "badge-ghost", freshness_badge_class(build(:menu_item))
  end
end
