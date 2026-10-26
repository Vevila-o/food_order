module MerchantsHelper
  # 外送費文字：未知 → 待確認（不是 0）；明確 0 → 免外送費；滿額免運另外標示
  def delivery_fee_text(merchant)
    fee = merchant.delivery_fee
    text = if fee.nil? then t("common.unknown_amount")
    elsif fee.zero? then "免外送費"
    else format_money(fee)
    end
    threshold = merchant.free_delivery_threshold
    threshold ? "#{text}（滿 #{format_money(threshold)} 免運）" : text
  end

  # 聯絡管道的顯示名稱（LINE / Instagram / Messenger / 電話）
  def channel_label(channel)
    t("enums.order_inquiry.contacted_via.#{channel}")
  end
end
