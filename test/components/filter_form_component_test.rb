require "test_helper"

class FilterFormComponentTest < ViewComponent::TestCase
  def render_form(params = {}, variant: :sidebar)
    render_inline(FilterFormComponent.new(filter: MerchantFilter.new(params), variant: variant))
  end

  test "GET 表單，只更新列表 Turbo Frame 並更新網址" do
    render_form

    assert_selector "form[method=get][action='/merchants'][data-turbo-frame=merchant-list][data-turbo-action=advance]"
  end

  test "欄位名稱放在 filter[...] 底下" do
    render_form

    assert_selector "input[type=radio][name='filter[kind]']", count: 4
    assert_selector "input[type=checkbox][name='filter[free_delivery]'][value='1']"
    assert_selector "select[name='filter[sort]']"
    MerchantFilter::FLAGS.each do |flag|
      assert_selector "input[type=checkbox][name='filter[#{flag}]']"
    end
  end

  test "每個旗標都有中文標籤" do
    assert_equal MerchantFilter::FLAGS.sort, FilterFormComponent::FLAG_LABELS.keys.sort
    assert_equal MerchantFilter::SORTS.sort, FilterFormComponent::SORT_LABELS.keys.sort
  end

  test "側欄：勾選就自動送出，沒有套用按鈕（只有沒 JS 時的 noscript）" do
    render_form(variant: :sidebar)

    assert_selector "form[data-controller=auto-submit][data-action='change->auto-submit#submit']"
    assert_no_selector "form > div > button[type=submit]"
  end

  test "抽屜：按套用才篩選，不自動送出" do
    render_form(variant: :drawer)

    assert_selector "button[type=submit]", text: "套用"
    assert_no_selector "form[data-controller=auto-submit]"
  end

  test "側欄與抽屜的 id 不重複（同一頁會同時出現）" do
    sidebar_ids = render_form(variant: :sidebar).css("[id]").map { |node| node["id"] }
    drawer_ids = render_form(variant: :drawer).css("[id]").map { |node| node["id"] }

    assert_empty sidebar_ids & drawer_ids
  end

  test "目前條件帶入勾選狀態" do
    render_form({ kind: "food_only", free_delivery: "1", sort: "price" })

    assert_selector "input[type=radio][value=food_only][checked]"
    assert_selector "input[type=radio][value=''][checked]", count: 0
    assert_selector "input[name='filter[free_delivery]'][checked]"
    assert_no_selector "input[name='filter[favorited]'][checked]"
    assert_selector "option[value=price][selected]"
  end

  test "沒有條件時預設選全部與預設排序" do
    render_form

    assert_selector "input[type=radio][value=''][checked]"
    assert_selector "option[value=recent][selected]"
  end

  test "有條件才顯示清除篩選" do
    render_form
    assert_no_selector "a", text: "清除篩選"

    render_form({ favorited: "1" })
    assert_selector "a[href='/merchants']", text: "清除篩選"
  end

  test "每個選項標籤都用 label 包住（可點擊區 ≥ 44px）" do
    render_form

    assert_selector "label.tap-target", minimum: 12
  end
end
