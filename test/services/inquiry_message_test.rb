require "test_helper"

class InquiryMessageTest < ActiveSupport::TestCase
  LOCATION = "PicCollage 公司總部（台北市大安區光復南路 102 號 3 樓）".freeze

  def build_text(event: build(:event, held_on: Date.new(2026, 10, 27)), lines: nil, subtotal: 1620, recipient: nil, invoice: nil)
    lines ||= [ InquiryMessage::Line.new(name: "雞腿便當", unit: "份", quantity: 18) ]
    InquiryMessage.new(event: event, location: LOCATION, lines: lines, subtotal: subtotal, recipient: recipient, invoice: invoice).text
  end

  test "照規格書範本：日期、星期、送達時段、地點、品項、小計" do
    assert_equal <<~TEXT.chomp, build_text
      您好！想詢問 10/27（週二）19:00–19:15 之間，是否能外送以下餐點到 PicCollage 公司總部（台北市大安區光復南路 102 號 3 樓）：
      - 雞腿便當 × 18 份
      依菜單價格估計小計約 NT$1,620。
      想請問是否需要外送費？
      謝謝！
    TEXT
  end

  test "星期由日期計算，不寫死週二" do
    assert_includes build_text(event: build(:event, held_on: Date.new(2026, 10, 28))), "10/28（週三）"
  end

  test "單位沒填：只寫數字" do
    lines = [ InquiryMessage::Line.new(name: "紅茶", unit: nil, quantity: 18), InquiryMessage::Line.new(name: "綠茶", unit: "", quantity: 2) ]

    text = build_text(lines: lines)

    assert_includes text, "- 紅茶 × 18\n"
    assert_includes text, "- 綠茶 × 2\n"
  end

  test "多個品項依序列出（餐點與飲料）" do
    lines = [ InquiryMessage::Line.new(name: "雞腿便當", unit: "份", quantity: 10), InquiryMessage::Line.new(name: "紅茶", unit: "杯", quantity: 10) ]

    assert_includes build_text(lines: lines), "- 雞腿便當 × 10 份\n- 紅茶 × 10 杯\n"
  end

  test "收件資訊有填才加一行，放在品項之後、小計之前" do
    with = build_text(recipient: "收件人：王小明，電話：0912-345-678").lines.map(&:chomp)
    without = build_text.lines.map(&:chomp)

    assert_equal "收件人：王小明，電話：0912-345-678", with[2]
    assert_equal without.size + 1, with.size
    assert_not_includes without.join, "收件人"
  end

  test "收件資訊是空字串也不加空行" do
    assert_equal build_text, build_text(recipient: "")
  end

  test "小計加千分位" do
    assert_includes build_text(subtotal: 12_345), "NT$12,345。"
  end

  test "to_s 與 text 相同" do
    msg = InquiryMessage.new(event: build(:event), location: LOCATION, lines: [], subtotal: 0)

    assert_equal msg.text, msg.to_s
  end

  test "發票統編有填才加一行，在收件資訊之後、小計之前" do
    lines = build_text(recipient: "收件人：王小明", invoice: "發票統一編號：12345678").lines.map(&:chomp)

    assert_equal "收件人：王小明", lines[2]
    assert_equal "發票統一編號：12345678", lines[3]
    assert_match(/\A依菜單價格估計小計/, lines[4])
    assert_not_includes build_text, "發票"
    assert_equal build_text, build_text(invoice: "")
  end

  test "不再附確認菜單價格的句子" do
    assert_not_includes build_text, "菜單價格是否有調整"
    assert_includes build_text, "想請問是否需要外送費？\n"
  end
end
