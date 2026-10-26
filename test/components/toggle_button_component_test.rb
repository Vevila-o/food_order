require "test_helper"

class ToggleButtonComponentTest < ViewComponent::TestCase
  def render_toggle(merchant, kind) = render_inline(ToggleButtonComponent.new(merchant: merchant, kind: kind))

  test "收藏：未按下時送 POST，星號不填色，背景是一般色" do
    merchant = create(:merchant)

    render_toggle(merchant, :favorite)

    assert_selector "form#favorite_merchant_#{merchant.id}[action='/merchants/#{merchant.id}/favorite'][method=post]"
    assert_no_selector "input[name=_method]"
    assert_selector "button[aria-label=收藏][aria-pressed=false].bg-base-200"
    assert_no_selector "svg.fill-accent"
  end

  test "收藏：已按下時送 DELETE，星號填 accent，背景是淡黃" do
    merchant = create(:merchant, favorited: true)

    render_toggle(merchant, :favorite)

    assert_selector "input[name=_method][value=delete]", visible: :all
    assert_selector "button[aria-pressed=true].bg-accent-soft"
    assert_selector "svg.fill-accent"
  end

  test "下次候選：書籤圖示，已按下填 warning、淡橘背景" do
    merchant = create(:merchant, shortlisted: true)

    render_toggle(merchant, :shortlist)

    assert_selector "form#shortlist_merchant_#{merchant.id}[action='/merchants/#{merchant.id}/shortlist']"
    assert_selector "button[aria-label=下次候選][aria-pressed=true].bg-warning-soft"
    assert_selector "svg.fill-warning"
  end

  test "點擊範圍 44px、有 title 提示、aria-label 固定（狀態由 aria-pressed 表達）" do
    render_toggle(create(:merchant), :favorite)

    assert_selector "button.size-11[title=收藏][aria-label=收藏]"
  end

  test "dom id 與 Turbo Stream 替換用的 id 一致" do
    merchant = create(:merchant)

    assert_equal "favorite_merchant_#{merchant.id}", ToggleButtonComponent.dom_id_for(merchant, :favorite)
    assert_equal "shortlist_merchant_#{merchant.id}", ToggleButtonComponent.dom_id_for(merchant, :shortlist)
  end

  test "不認得的種類直接報錯" do
    assert_raises(KeyError) { render_toggle(create(:merchant), :nope) }
  end
end
