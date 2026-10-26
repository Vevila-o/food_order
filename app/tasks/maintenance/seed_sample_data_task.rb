# frozen_string_literal: true

module Maintenance
  # 建立開發用範例資料（店家名稱以「【範例】」開頭，可重複執行，正式環境不可執行）。
  class SeedSampleDataTask < MaintenanceTasks::Task
    no_collection

    def process
      count = SampleData.create!
      Rails.logger.info("[SeedSampleDataTask] 建立 #{count} 間範例店家")
    end
  end
end
