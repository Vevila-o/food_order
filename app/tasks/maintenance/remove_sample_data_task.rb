# frozen_string_literal: true

module Maintenance
  # 移除「【範例】」開頭的店家、詢問單、訂購紀錄與範例活動（正式環境不可執行）。
  class RemoveSampleDataTask < MaintenanceTasks::Task
    no_collection

    def process
      count = SampleData.remove!
      Rails.logger.info("[RemoveSampleDataTask] 移除 #{count} 間範例店家")
    end
  end
end
