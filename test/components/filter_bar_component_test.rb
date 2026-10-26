require "test_helper"

class FilterBarComponentTest < ViewComponent::TestCase
  def render_bar(params = {})
    render_inline(FilterBarComponent.new(filter: MerchantFilter.new(params)))
  end

  test "單一 GET 表單，只更新列表 Turbo Frame 並更新網址，變更即自動送出" do
    render_bar

    assert_selector "form#filter-form[method=get][action='/merchants'][data-turbo-frame=merchant-list][data-turbo-action=advance]"
    assert_selector "form#filter-form[data-controller=auto-submit][data-action='change->auto-submit#submit']"
  end

  test "設計稿的 7 個膠囊，都是原生 checkbox（鍵盤與讀屏可用）" do
    render_bar

    assert_selector "form#filter-form input[type=checkbox].peer", count: 7
    FilterBarComponent::CHIPS.each do |_, _, label|
      assert_selector "label span", text: label
    end
  end

  test "類型是可複選的 filter[kinds][]，其餘是 filter[旗標]" do
    render_bar

    assert_selector "input[name='filter[kinds][]'][value=food_and_drink]"
    assert_selector "input[name='filter[free_delivery]'][value='1']"
  end

  test "膠囊的 label 是 relative：隱藏的 checkbox 不會跑出捲動區而撐寬頁面" do
    render_bar

    assert_selector "label.relative", count: 7
  end

  test "膠囊的點擊範圍 ≥ 44px（手機）" do
    render_bar

    assert_selector "label span.min-h-11", count: 7
  end

  test "抽屜的欄位用 form 屬性歸屬同一個表單，膠囊與抽屜狀態一致" do
    render_bar

    assert_selector "dialog input[form=filter-form]", minimum: 4
    assert_selector "dialog select[form=filter-form][name='filter[sort]']"
    assert_selector "dialog button[type=submit][form=filter-form]", text: "套用"
  end

  test "每個 checkbox 的 id 都不重複" do
    ids = render_bar.css("input[id]").map { |node| node["id"] }

    assert_equal ids.uniq, ids
  end

  test "目前條件帶入勾選與排序" do
    render_bar({ kinds: [ "food_and_drink", "drink_only" ], free_delivery: "1", never_ordered: "1", sort: "price" })

    assert_selector "input[value=food_and_drink][checked]"
    assert_selector "dialog input[value=drink_only][checked]"
    assert_selector "input[name='filter[free_delivery]'][checked]"
    assert_selector "dialog input[name='filter[never_ordered]'][checked]"
    assert_no_selector "input[name='filter[favorited]'][checked]"
    assert_selector "dialog option[value=price][selected]"
  end

  test "沒有條件時預設排序" do
    render_bar

    assert_selector "dialog option[value=recent][selected]"
  end

  test "「更多篩選」顯示抽屜裡啟用的條件數（含排序）" do
    render_bar({ kinds: [ "drink_only" ], daan: "1", sort: "name", favorited: "1" })

    assert_selector "button[data-action='dialog#open']", text: "更多篩選 (3)"
  end

  test "沒有抽屜條件時不顯示數字" do
    render_bar({ favorited: "1" })

    assert_selector "button[data-action='dialog#open']", text: /\A\s*更多篩選\s*\z/
  end

  test "有條件才顯示抽屜裡的清除全部篩選" do
    render_bar
    assert_no_selector "dialog a", text: "清除全部篩選"

    render_bar({ favorited: "1" })
    assert_selector "dialog a[href='/merchants']", text: "清除全部篩選"
  end

  test "抽屜是原生 dialog，可由 Stimulus 開關；整塊包在 dialog controller 裡" do
    render_bar

    assert_selector "div[data-controller=dialog][data-action='turbo:submit-end->dialog#close'] dialog[data-dialog-target=dialog]"
  end

  test "每個旗標都在膠囊列或抽屜出現（不會漏掉篩選條件）" do
    shown = (FilterBarComponent::CHIPS + FilterBarComponent::DRAWER_CHECKS).map(&:first).uniq - [ "kinds" ]

    assert_equal MerchantFilter::FLAGS.sort, shown.sort
    kinds = (FilterBarComponent::CHIPS + FilterBarComponent::DRAWER_CHECKS).select { |name, _, _| name == "kinds" }.map { |_, value, _| value }
    assert_equal MerchantFilter::KINDS.sort, kinds.sort
    assert_equal MerchantFilter::SORTS.sort, FilterBarComponent::SORT_LABELS.keys.sort
  end
end
