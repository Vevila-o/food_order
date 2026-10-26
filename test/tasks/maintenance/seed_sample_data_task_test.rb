# frozen_string_literal: true

require "test_helper"

module Maintenance
  class SeedSampleDataTaskTest < ActiveSupport::TestCase
    test "建立範例店家、菜單、活動與人數" do
      Maintenance::SeedSampleDataTask.process

      assert_equal 5, Merchant.count
      assert Merchant.pluck(:name).all? { |name| name.start_with?(SampleData::PREFIX) }
      assert_equal 1, Event.count
      assert_equal 18, Event.first.headcount
      assert_equal "週二", Event.first.weekday_label
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

    test "可重複執行，不會重複建立" do
      Maintenance::SeedSampleDataTask.process

      assert_no_difference [ "Merchant.count", "MenuItem.count", "Event.count", "OrderRecord.count" ] do
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
