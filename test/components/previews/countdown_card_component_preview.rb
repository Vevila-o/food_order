class CountdownCardComponentPreview < ViewComponent::Preview
  # 還有 12 天 5 小時（固定「現在」，預覽才不會每天不一樣）
  def upcoming
    render_card(now: Time.zone.local(2026, 10, 22, 14, 30), held_on: Date.new(2026, 11, 3))
  end

  # 當天、距離開始不到一天：0 天
  def same_day
    render_card(now: Time.zone.local(2026, 11, 3, 9, 0), held_on: Date.new(2026, 11, 3))
  end

  # 已經開始或日期已過：顯示說明與「設定下一場」
  def started
    render_card(now: Time.zone.local(2026, 11, 3, 20, 0), held_on: Date.new(2026, 11, 3))
  end

  private

  def render_card(now:, held_on:)
    event = Event.new(held_on: held_on, kktix_slug: "rubyjam2611", title: "預覽")
    render CountdownCardComponent.new(event: event, edit_href: "/events/1/edit", now: now)
  end
end
