# frozen_string_literal: true

require "test_helper"

module Maintenance
  class RemoveSampleDataTaskTest < ActiveSupport::TestCase
    test "移除範例店家、菜單、訂購紀錄與範例活動" do
      Maintenance::SeedSampleDataTask.process

      Maintenance::RemoveSampleDataTask.process

      assert_equal 0, Merchant.count
      assert_equal 0, MenuItem.count
      assert_equal 0, OrderRecord.count
      assert_equal 0, OrderInquiry.count
      assert_equal 0, OrderInquiryItem.count
      assert_equal 0, Event.count
    end

    test "範例店家已有詢問單也能移除（先清歷史再刪店家）" do
      Maintenance::SeedSampleDataTask.process
      merchant = Merchant.find_by!(name: "#{SampleData::PREFIX}阿嬤便當")
      event = Event.order(:held_on).last
      inquiry = create(:order_inquiry, merchant: merchant, event: create(:event, held_on: event.held_on + 60))
      inquiry.confirm!

      Maintenance::RemoveSampleDataTask.process

      assert_equal 0, Merchant.count
      assert_equal 0, OrderInquiry.count
    end

    test "沒有範例資料時不會出錯" do
      assert_nothing_raised { Maintenance::RemoveSampleDataTask.process }
    end

    test "正式環境拒絕執行" do
      with_rails_env("production") do
        assert_raises(SampleData::ProductionError) { Maintenance::RemoveSampleDataTask.process }
      end
    end
  end
end
