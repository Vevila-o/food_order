require "test_helper"

class CountdownCardComponentTest < ViewComponent::TestCase
  def card(now:, held_on: Date.new(2026, 11, 3), **options)
    render_inline(CountdownCardComponent.new(event: build(:event, held_on: held_on), now: now, **options))
  end

  test "顯示天與小時（兩位數），活動 19:30 開始" do
    card(now: Time.zone.local(2026, 10, 22, 14, 30)) # 還有 12 天 5 小時

    assert_selector "span", text: "12"
    assert_selector "span", text: "05"
    assert_selector "span", text: "天 dd"
    assert_selector "span", text: "時 hh"
  end

  test "螢幕閱讀器唸完整句子，數字方塊是裝飾（aria-hidden）" do
    card(now: Time.zone.local(2026, 10, 22, 14, 30))

    assert_selector "p.sr-only", text: "距離下一場 Ruby Jam 還有 12 天 5 小時"
    assert_selector "div[aria-hidden=true]"
  end

  test "小時無條件捨去：差 12 天又 5 小時 59 分仍是 5 小時" do
    card(now: Time.zone.local(2026, 10, 22, 13, 31))

    assert_selector "span", text: "05"
  end

  test "當天、不到一天：0 天" do
    card(now: Time.zone.local(2026, 11, 3, 9, 0))

    assert_selector "span", text: "00"
    assert_selector "span", text: "10"
  end

  test "活動已開始（剛好 19:30 或之後）：顯示已開始或已結束，不顯示數字方塊" do
    [ Time.zone.local(2026, 11, 3, 19, 30), Time.zone.local(2026, 11, 4, 8, 0) ].each do |now|
      card(now: now, edit_href: "/events/1/edit")

      assert_text "已開始或已結束"
      assert_no_selector "div[aria-hidden=true]"
      assert_selector "a[href='/events/1/edit']", text: "設定下一場"
    end
  end

  test "沒給 edit_href：不顯示設定連結" do
    card(now: Time.zone.local(2026, 11, 4, 8, 0))

    assert_no_link "設定下一場"
  end

  test "卡片有陰影" do
    card(now: Time.zone.local(2026, 10, 22, 14, 30))

    assert_selector "section.shadow-md"
  end

  test "標題是「倒數」；數字方塊撐滿標題下方的空白" do
    card(now: Time.zone.local(2026, 10, 22, 14, 30))

    assert_selector "h2", text: "倒數"
    assert_selector "div.grid.flex-1.grid-cols-2[aria-hidden=true]"
    assert_selector "div.grid > div.justify-center", count: 2
  end
end
