require "test_helper"

class EventFormTest < ActiveSupport::TestCase
  test "新增活動：預設日期是下一個週二，儲存後自動產生活動代碼與名稱" do
    travel_to Time.zone.local(2026, 10, 22, 12, 0) do # 週四
      form = EventForm.new
      assert_equal Date.new(2026, 10, 27), form.held_on

      assert form.save
      assert_equal "rubyjam2610", form.event.kktix_slug
      assert_equal "Ruby Jam 2026 年 10 月", form.event.title
    end
  end

  test "新增活動並填人數：寫入一筆手動快照" do
    form = EventForm.new(Event.new, held_on: "2026-11-24", headcount: "20")

    assert_difference [ "Event.count", "RegistrationSnapshot.count" ], 1 do
      assert form.save
    end
    assert_equal 20, form.event.headcount
    assert_equal "manual", form.event.latest_snapshot.source
  end

  test "人數沒填或和目前相同：不新增快照" do
    event = create(:event, :with_headcount, headcount: 18)

    assert_no_difference "RegistrationSnapshot.count" do
      assert EventForm.new(event, headcount: "").save
      assert EventForm.new(event, headcount: "18").save
    end
  end

  test "修正人數：新增一筆快照，保留舊紀錄，目前人數是最新一筆" do
    event = create(:event, :with_headcount, headcount: 18)

    assert_difference "RegistrationSnapshot.count", 1 do
      assert EventForm.new(event, headcount: "21").save
    end
    assert_equal 21, event.reload.headcount
    assert_equal [ 18, 21 ], event.registration_snapshots.order(:id).pluck(:headcount)
  end

  test "修正人數可以改成 0" do
    event = create(:event, :with_headcount, headcount: 18)

    assert EventForm.new(event, headcount: "0").save
    assert_equal 0, event.reload.headcount
  end

  test "人數必須是 0–999 的整數" do
    [ "-1", "1000", "abc", "1.5" ].each do |value|
      form = EventForm.new(Event.new, held_on: "2026-11-24", headcount: value)

      assert_not form.save, value
      assert form.errors.key?(:headcount), value
    end
  end

  test "沒有日期不能儲存，且不會留下半成品" do
    form = EventForm.new(Event.new, held_on: "", headcount: "10")

    assert_no_difference [ "Event.count", "RegistrationSnapshot.count" ] do
      assert_not form.save
    end
    assert form.errors.key?(:held_on)
  end

  test "活動代碼重複：回報在表單上，人數快照不會寫入" do
    create(:event, held_on: Date.new(2026, 11, 24))
    form = EventForm.new(Event.new, held_on: "2026-11-24", headcount: "10")

    assert_no_difference [ "Event.count", "RegistrationSnapshot.count" ] do
      assert_not form.save
    end
    assert form.errors.key?(:kktix_slug)
  end

  test "改日期而代碼還是自動產生的舊值：代碼與名稱跟著更新" do
    event = create(:event, held_on: Date.new(2026, 10, 27))

    assert EventForm.new(event, held_on: "2026-11-24", kktix_slug: "rubyjam2610").save
    assert_equal "rubyjam2611", event.reload.kktix_slug
    assert_equal "Ruby Jam 2026 年 11 月", event.title
  end

  test "代碼是手動改過的：改日期不會覆蓋" do
    event = create(:event, held_on: Date.new(2026, 10, 27), kktix_slug: "rubyjam-special", title: "特別場")

    assert EventForm.new(event, held_on: "2026-11-24", kktix_slug: "rubyjam-special").save
    assert_equal "rubyjam-special", event.reload.kktix_slug
    assert_equal "特別場", event.title
  end

  test "非週二：unusual_weekday? 為真，但仍可儲存" do
    form = EventForm.new(Event.new, held_on: "2026-10-28")

    assert form.unusual_weekday?
    assert form.save
    assert_not EventForm.new(Event.new, held_on: "2026-10-27").unusual_weekday?
  end

  test "活動日期已過也可以儲存（下一場日期常常還不確定）" do
    travel_to Time.zone.local(2026, 12, 1) do
      assert EventForm.new(Event.new, held_on: "2026-10-27").save
    end
  end
end
