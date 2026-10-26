require "test_helper"

class MenuTextParserTest < ActiveSupport::TestCase
  def parse(text) = MenuTextParser.call(text)

  def pairs(text) = parse(text).items.map { |item| [ item.name, item.price ] }

  test "品名 空白 價格" do
    assert_equal [ [ "雞腿飯", 90 ] ], pairs("雞腿飯 90")
  end

  test "各種價格寫法" do
    {
      "雞腿飯 $90" => 90,
      "雞腿飯 NT$90" => 90,
      "雞腿飯 nt$90" => 90,
      "雞腿飯 90元" => 90,
      "雞腿飯 90 元" => 90,
      "雞腿飯 90塊" => 90,
      "雞腿飯：90" => 90,
      "雞腿飯: 90" => 90,
      "雞腿飯 - 90" => 90,
      "雞腿飯 — 90" => 90,
      "雞腿飯...90" => 90,
      "雞腿飯……90" => 90,
      "雞腿飯/90" => 90,
      "雞腿飯\t90" => 90,
      "雞腿飯90" => 90,
      "雞腿飯 1,280" => 1280
    }.each do |line, price|
      assert_equal [ [ "雞腿飯", price ] ], pairs(line), "「#{line}」應解析為 #{price}"
    end
  end

  test "全形數字、全形空白、全形冒號與全形錢字號" do
    assert_equal [ [ "雞腿飯", 90 ] ], pairs("雞腿飯　９０")
    assert_equal [ [ "排骨飯", 85 ] ], pairs("排骨飯：８５")
    assert_equal [ [ "控肉飯", 80 ] ], pairs("控肉飯 ＄８０元")
    assert_equal [ [ "套餐", 1280 ] ], pairs("套餐 １，２８０")
  end

  test "品名可以包含數字、英文與括號，括號不會被改成半形" do
    assert_equal [ [ "3號餐", 120 ] ], pairs("3號餐 120")
    assert_equal [ [ "套餐A", 130 ] ], pairs("套餐A130")
    assert_equal [ [ "紅茶（大杯）", 35 ] ], pairs("紅茶（大杯） 35")
    assert_equal [ [ "鋁箔包紅茶（一箱 24 入）", 360 ] ], pairs("鋁箔包紅茶（一箱 24 入） 360")
    assert_equal [ [ "可樂 500ml", 30 ] ], pairs("可樂 500ml 30")
  end

  test "多行：略過空白行，保留順序" do
    result = parse("雞腿飯 90\n\n  排骨飯 85  \r\n\n控肉飯 80\n")

    assert result.ok?
    assert_equal [ [ "雞腿飯", 90 ], [ "排骨飯", 85 ], [ "控肉飯", 80 ] ], result.items.map { |i| [ i.name, i.price ] }
  end

  test "行號是使用者看到的原始行號（空白行也算）" do
    result = parse("雞腿飯 90\n\n排骨飯 85")

    assert_equal [ 1, 3 ], result.items.map(&:line)
  end

  test "品名中多餘空白會合併" do
    assert_equal [ [ "雞 腿 飯", 90 ] ], pairs("  雞   腿  飯    90 ")
  end

  test "空字串與 nil 沒有品項也沒有錯誤" do
    assert_predicate parse(""), :ok?
    assert_empty parse(nil).items
    assert_empty parse("  \n \n").items
  end

  test "找不到價格：回報行號與原文，不默默忽略" do
    result = parse("雞腿飯 90\n今日特餐\n排骨飯 85")

    assert_not result.ok?
    assert_equal [ [ "雞腿飯", 90 ], [ "排骨飯", 85 ] ], result.items.map { |i| [ i.name, i.price ] }
    assert_equal 2, result.errors.first.line
    assert_equal "今日特餐", result.errors.first.text
    assert_match(/找不到價格/, result.errors.first.message)
  end

  test "只有價格沒有品名" do
    error = parse("90").errors.first

    assert_match(/缺少品名/, error.message)
  end

  test "價格 0 或過大視為不合理" do
    assert_match(/價格需介於/, parse("免費贈品 0").errors.first.message)
    assert_match(/價格需介於/, parse("雞腿飯 100000").errors.first.message)
    assert_empty parse("雞腿飯 99999").errors
  end

  test "同一行兩個價格（90/110）無法判斷，回報錯誤而不是亂猜" do
    error = parse("雞腿飯 90/110").errors.first

    assert_match(/品名最後是數字/, error.message)
  end

  test "品名重複：回報第二次出現的行，並指出第一次的行號" do
    result = parse("雞腿飯 90\n排骨飯 85\n雞腿飯 95")

    assert_equal 2, result.items.size
    assert_equal 3, result.errors.first.line
    assert_match(/重複（第 1 行已出現）/, result.errors.first.message)
  end

  test "品名過長" do
    assert_match(/品名過長/, parse("#{'飯' * 101} 90").errors.first.message)
  end

  test "一次最多 200 行" do
    result = parse((1..201).map { |n| "品項#{('A'.ord + n % 26).chr} #{n}" }.join("\n"))

    assert_not result.ok?
    assert_match(/最多 200 行/, result.errors.first.message)
    assert_empty result.items
  end

  test "惡意內容只會被當成品名文字，不會被執行" do
    result = parse("<script>alert(1)</script> 90")

    assert_equal "<script>alert(1)</script>", result.items.first.name
  end
end
