class EventSummaryComponentPreview < ViewComponent::Preview
  # 人數 18、總預算 NT$1,800，沒有需要調整的詢問單
  def default
    render EventSummaryComponent.new(event: build_event(headcount: 18))
  end

  # 詢問單建立時是 16 人，現在 18 人：顯示「比上次詢問 +2 人，需調整訂餐」
  def needs_adjustment
    render EventSummaryComponent.new(event: build_event(headcount: 18, inquiry_headcount: 16))
  end

  # 有給 edit_href 時，人數旁顯示「修正人數」連結
  def with_edit_link
    render EventSummaryComponent.new(event: build_event(headcount: 18), edit_href: "/events/1/edit")
  end

  # 人數變少
  def fewer_people
    render EventSummaryComponent.new(event: build_event(headcount: 15, inquiry_headcount: 18))
  end

  # 還沒填人數
  def no_headcount
    render EventSummaryComponent.new(event: build_event(headcount: nil))
  end

  private

  # 只在記憶體建立（不寫資料庫）：人數用單例方法覆寫，詢問單用 build 加入關聯
  def build_event(headcount:, inquiry_headcount: nil)
    event = Event.new(held_on: Date.current.next_occurring(:tuesday), kktix_slug: "rubyjam2610", title: "預覽")
    event.define_singleton_method(:headcount) { headcount }
    event.order_inquiries.build(headcount_at_creation: inquiry_headcount, subtotal: 1500, created_at: Time.current) if inquiry_headcount
    event
  end
end
