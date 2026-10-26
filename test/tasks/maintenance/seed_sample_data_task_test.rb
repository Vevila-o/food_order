# frozen_string_literal: true

require "test_helper"

module Maintenance
  class SeedSampleDataTaskTest < ActiveSupport::TestCase
    test "建立範例店家、菜單、活動與人數" do
      Maintenance::SeedSampleDataTask.process

      assert_equal 5, Merchant.count
      assert Merchant.pluck(:name).all? { |name| name.start_with?(SampleData::PREFIX) }
      assert_equal 2, Event.count, "本場與過去一場"
      assert_equal [ 16, 18 ], Event.all.map(&:headcount).sort
      assert Event.all.all? { |event| event.weekday_label == "週二" }
    end

    test "範例資料涵蓋各種情境" do
      Maintenance::SeedSampleDataTask.process

      assert_equal 1, Merchant.drink_only.count, "要有只賣飲料的店"
      assert_equal 1, Merchant.where(delivers_at_19: "no").count
      assert_equal 1, Merchant.ordered_before.count
      assert_equal 1, Merchant.shortlisted.count
      assert_equal 1, Merchant.favorited.count
      assert Merchant.all.any? { |merchant| merchant.contact_links.empty? }, "要有沒有聯絡方式的店"
      assert MenuItem.stale.exists?
      assert MenuItem.date_unknown.exists?
      assert MenuItem.where.not(servings: nil).exists?
    end

    test "建立詢問單與訂購紀錄，側欄的已詢問、已訂購才有內容" do
      Maintenance::SeedSampleDataTask.process

      assert_equal 3, OrderInquiry.count
      assert_equal %w[confirmed draft sent], OrderInquiry.pluck(:status).sort
      assert OrderInquiry.all.all? { |inquiry| inquiry.items.any? }
      assert_equal 2, OrderRecord.count, "一筆手動補登 + 一筆確認訂購自動產生"
      assert_equal %w[inquiry manual], OrderRecord.pluck(:source).sort
    end

    test "詢問單金額與品項快照一致，外送費未知的草稿金額是 NULL" do
      Maintenance::SeedSampleDataTask.process

      OrderInquiry.all.each do |inquiry|
        assert_equal inquiry.subtotal, inquiry.items.sum(&:line_total)
      end
      draft = OrderInquiry.find_by!(status: "draft")
      assert_nil draft.total, "外送費未知，預計金額不能當 0"
    end

    test "可重複執行，不會重複建立" do
      Maintenance::SeedSampleDataTask.process

      assert_no_difference [ "Merchant.count", "MenuItem.count", "Event.count", "OrderRecord.count", "OrderInquiry.count", "OrderInquiryItem.count" ] do
        Maintenance::SeedSampleDataTask.process
      end
    end

    test "不會動到真實資料" do
      real = create(:merchant, name: "真實便當")

      Maintenance::SeedSampleDataTask.process
      Maintenance::RemoveSampleDataTask.process

      assert Merchant.exists?(real.id)
    end

    test "正式環境拒絕執行" do
      with_rails_env("production") do
        assert_raises(SampleData::ProductionError) { Maintenance::SeedSampleDataTask.process }
      end
      assert_equal 0, Merchant.count
    end
  end
end
