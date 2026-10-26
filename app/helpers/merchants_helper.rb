module MerchantsHelper
  # 店家類型標籤：餐＋飲 / 只有餐 / 僅飲料
  def kind_label(merchant)
    t("merchant_kind.#{merchant.kind}")
  end

  # 標籤顏色：餐＋飲用 accent（色票規定）、僅飲料用 secondary、只有餐用中性
  def kind_badge_class(merchant)
    case merchant.kind
    when :food_and_drink then "badge-accent"
    when :drink_only then "badge-secondary"
    else "badge-ghost"
    end
  end

  # 菜單新鮮度文字與樣式（過期用 warning，日期不明用 ghost）
  def freshness_label(menu_item)
    t("menu_freshness.#{menu_item.freshness}")
  end

  def freshness_badge_class(menu_item)
    case menu_item.freshness
    when :fresh then "badge-ghost"
    else "badge-warning"
    end
  end
end
