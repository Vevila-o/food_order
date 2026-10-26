require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "依日期自動產生活動代碼與標題" do
    event = create(:event, held_on: Date.new(2026, 10, 27))

    assert_equal "rubyjam2610", event.kktix_slug
    assert_equal "Ruby Jam 2026 年 10 月", event.title
  end

  test "活動代碼可手動修改，且不可重複" do
    create(:event, kktix_slug: "rubyjam2610")

    assert_not build(:event, held_on: Date.new(2026, 10, 20), kktix_slug: "rubyjam2610").valid?
    assert_equal "rubyjam-special", create(:event, held_on: Date.new(2026, 11, 17), kktix_slug: "rubyjam-special").kktix_slug
  end

  test "活動日期必填" do
    assert_not build(:event, held_on: nil).valid?
  end

  test "KKTIX 後台參加者網址" do
    event = create(:event)

    assert_equal "https://kktix.com/dashboard/events/rubyjam2610/attendees", event.kktix_attendees_url
  end

  test "星期由日期計算，不寫死週二" do
    assert_equal "週二", build(:event, held_on: Date.new(2026, 10, 27)).weekday_label
    assert_equal "週三", build(:event, held_on: Date.new(2026, 10, 28)).weekday_label
  end

  test "送達時段預設 19:00–19:15、活動 19:30，不受時區影響" do
    event = create(:event).reload

    assert_equal "19:00–19:15", event.delivery_window_label
    assert_equal "19:30", event.starts_at.strftime("%H:%M")
  end

  test "沒有任何快照時沒有人數與預算" do
    event = create(:event)

    assert_nil event.headcount
    assert_nil event.total_budget
  end

  test "人數以最新一筆快照為準（含手動修正）" do
    event = create(:event)
    create(:registration_snapshot, event: event, headcount: 15, received_at: 2.days.ago)
    create(:registration_snapshot, event: event, headcount: 19, received_at: 1.day.ago)
    create(:registration_snapshot, event: event, headcount: 12, received_at: 3.days.ago)

    assert_equal 19, event.headcount
  end

  test "總預算 = 人數 × NT$100，下限 = 人數 × NT$80" do
    event = create(:event, :with_headcount, headcount: 18)

    assert_equal 1800, event.total_budget
    assert_equal 1440, event.min_budget
  end

  test "目前活動：最近一場還沒舉行（含今天）的" do
    travel_to Time.zone.local(2026, 10, 27, 12, 0) do
      create(:event, held_on: Date.new(2026, 9, 15))
      today = create(:event, held_on: Date.new(2026, 10, 27))
      create(:event, held_on: Date.new(2026, 11, 17))

      assert_equal today, Event.current
    end
  end

  test "目前活動：都已過去時取最近一場，沒有活動時為 nil" do
    travel_to Time.zone.local(2026, 12, 1, 12, 0) do
      assert_nil Event.current
      create(:event, held_on: Date.new(2026, 9, 15))
      latest = create(:event, held_on: Date.new(2026, 10, 27))

      assert_equal latest, Event.current
    end
  end

  test "default_date：今天起算的下一個週二（今天是週二就是今天）" do
    assert_equal Date.new(2026, 10, 27), Event.default_date(Date.new(2026, 10, 22)) # 週四
    assert_equal Date.new(2026, 10, 27), Event.default_date(Date.new(2026, 10, 27)) # 週二
    assert_equal Date.new(2026, 11, 3), Event.default_date(Date.new(2026, 10, 28)) # 週三
    assert_equal Date.new(2026, 10, 27), Event.default_date(Date.new(2026, 10, 25)) # 週日
  end

  test "title_for" do
    assert_equal "Ruby Jam 2026 年 11 月", Event.title_for(Date.new(2026, 11, 24))
  end
end
