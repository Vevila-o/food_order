require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  test "新增表單：日期預設下一個週二" do
    travel_to Time.zone.local(2026, 10, 22, 12, 0) do
      get new_event_path

      assert_response :success
      assert_select "input[type=date][name='event[held_on]'][value='2026-10-27']"
      assert_select "input[name='event[kktix_slug]']"
      assert_select "input[type=number][name='event[headcount]']"
    end
  end

  test "新增活動：存檔後回首頁，顯示日期、人數與預算" do
    assert_difference [ "Event.count", "RegistrationSnapshot.count" ], 1 do
      post events_path, params: { event: { held_on: "2026-11-24", kktix_slug: "", headcount: "20" } }
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_select ".alert", text: /已新增活動/
    assert_select "dd", text: "20 人"
    assert_select "dd", text: "NT$2,000"
  end

  test "新增活動：日期不是週二只提醒、不擋" do
    assert_difference "Event.count", 1 do
      post events_path, params: { event: { held_on: "2026-11-25" } }
    end

    assert_equal "已新增活動。注意：11/25 是週三，Ruby Jam 通常在週二", flash[:alert]
  end

  test "新增活動：沒有日期顯示錯誤並保留填寫內容" do
    assert_no_difference "Event.count" do
      post events_path, params: { event: { held_on: "", headcount: "9" } }
    end

    assert_response :unprocessable_content
    assert_select ".alert", text: /活動日期/
    assert_select "input[name='event[headcount]'][value='9']"
  end

  test "編輯表單帶入目前的日期、代碼與人數" do
    event = create(:event, :with_headcount, held_on: Date.new(2026, 10, 27), headcount: 18)

    get edit_event_path(event)

    assert_response :success
    assert_select "form[action='#{event_path(event)}'] input[name=_method][value=patch]"
    assert_select "input[name='event[held_on]'][value='2026-10-27']"
    assert_select "input[name='event[kktix_slug]'][value=rubyjam2610]"
    assert_select "input[name='event[headcount]'][value='18']"
  end

  test "修正人數：新增快照，首頁人數更新" do
    event = create(:event, :with_headcount, headcount: 18)

    assert_difference "RegistrationSnapshot.count", 1 do
      patch event_path(event), params: { event: { held_on: "2026-10-27", headcount: "22" } }
    end

    assert_redirected_to root_path
    assert_equal 22, event.reload.headcount
  end

  test "人數改變而詢問單還是舊人數：首頁出現需調整訂餐" do
    travel_to Time.zone.local(2026, 10, 22, 12, 0) do
      event = create(:event, :with_headcount, headcount: 16)
      create(:order_inquiry, event: event, headcount_at_creation: 16)

      patch event_path(event), params: { event: { held_on: "2026-10-27", headcount: "18" } }
      follow_redirect!

      assert_select "span", text: "比上次詢問 +2 人，需調整訂餐"
    end
  end

  test "更新失敗：422 並重新顯示表單" do
    event = create(:event)

    patch event_path(event), params: { event: { held_on: "" } }

    assert_response :unprocessable_content
  end

  test "不存在的活動回 404" do
    get edit_event_path(id: 0)

    assert_response :not_found
  end

  test "缺少參數回 400，不會 500" do
    post events_path, params: {}

    assert_response :bad_request
  end

  test "活動不能被刪除（沒有 destroy 路由）" do
    delete "/events/1"

    assert_response :not_found
  end

  test "需要 Basic Auth" do
    with_env(AUTH_ENV) do
      get new_event_path
      assert_response :unauthorized

      get new_event_path, headers: basic_auth_headers("jam", "s3cret-pass")
      assert_response :success
    end
  end
end
