# 把貼上的菜單文字解析成「品名 + 價格」。純 Ruby，不碰資料庫。
#
# 每行一個品項，容許的寫法：
#   雞腿飯 90 / 雞腿飯 $90 / 雞腿飯 NT$90 / 雞腿飯 90元 / 雞腿飯：90 / 雞腿飯 - 90 / 雞腿飯...90 / 雞腿飯　９０（全形）
#   3號餐 120（品名可以有數字，價格一律是最後一個數字）
# 解析不了的行不會默默忽略，而是回報行號與原因，讓使用者修正。
class MenuTextParser
  Item = Data.define(:name, :price, :line)
  LineError = Data.define(:line, :text, :message)
  Result = Data.define(:items, :errors) do
    def ok? = errors.empty?
  end

  MAX_LINES = 200
  MAX_PRICE = 99_999
  MAX_NAME_LENGTH = 100

  # 全形數字與符號轉半形（只轉這幾個，不用 NFKC，避免把品名裡的「（）」「…」也改掉）
  FULLWIDTH = "０１２３４５６７８９＄，：　"
  HALFWIDTH = "0123456789$,: "

  # 品名（越短越好）+ 分隔符號 + 價格（最後一個數字）+ 選填的「元」
  LINE_PATTERN = /\A(?<name>.*?)[\s:.\-–—\/|、,…·・]*(?:NT)?\$?\s*(?<price>\d[\d,]*)\s*(?:元|塊|圓)?\s*\z/i

  def self.call(text)
    new(text).call
  end

  def initialize(text)
    @text = text.to_s
  end

  def call
    lines = numbered_lines
    return Result.new(items: [], errors: [ LineError.new(line: 0, text: "", message: "一次最多 #{MAX_LINES} 行") ]) if lines.size > MAX_LINES

    items = []
    errors = []
    seen = {}

    lines.each do |number, raw|
      item_or_error = parse_line(number, raw)
      if item_or_error.is_a?(LineError)
        errors << item_or_error
      elsif (first = seen[item_or_error.name])
        errors << LineError.new(line: number, text: raw, message: "品名「#{item_or_error.name}」重複（第 #{first} 行已出現）")
      else
        seen[item_or_error.name] = number
        items << item_or_error
      end
    end

    Result.new(items: items, errors: errors)
  end

  private

  # [[行號, 原文], ...]，略過空白行，行號是使用者看到的原始行號
  def numbered_lines
    @text.lines.each_with_index.filter_map do |line, index|
      stripped = line.strip
      [ index + 1, stripped ] unless stripped.empty?
    end
  end

  def parse_line(number, raw)
    normalized = raw.tr(FULLWIDTH, HALFWIDTH)
    match = LINE_PATTERN.match(normalized)
    return error(number, raw, "找不到價格（請在品名後面加上價格，例如「雞腿飯 90」）") unless match

    name = match[:name].gsub(/[[:space:]]+/, " ").strip.sub(/[\s:.\-–—\/|、,…·・]+\z/, "")
    price = match[:price].delete(",").to_i

    return error(number, raw, "缺少品名") if name.empty?
    return error(number, raw, "品名過長（最多 #{MAX_NAME_LENGTH} 字）") if name.length > MAX_NAME_LENGTH
    # 「雞腿飯 90/110」會被解析成品名「雞腿飯 90」、價格 110：品名最後是數字就無法判斷哪個才是價格
    return error(number, raw, "品名最後是數字，無法判斷哪個是價格（請只留一個價格，或在品名後加單位，例如「500ml」）") if name.match?(/\d\z/)
    return error(number, raw, "價格需介於 1 到 #{MAX_PRICE}") unless price.between?(1, MAX_PRICE)

    Item.new(name: name, price: price, line: number)
  end

  def error(number, raw, message)
    LineError.new(line: number, text: raw, message: message)
  end
end
