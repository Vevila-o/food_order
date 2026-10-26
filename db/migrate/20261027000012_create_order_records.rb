class CreateOrderRecords < ActiveRecord::Migration[8.1]
  def change
    # 歷史訂購紀錄：詢問單確認訂購時自動建立（inquiry），或手動補登舊紀錄（manual）
    create_table :order_records do |t|
      t.references :merchant, null: false, foreign_key: { on_delete: :restrict }
      t.references :event, foreign_key: { on_delete: :nullify }
      t.references :order_inquiry, foreign_key: { on_delete: :cascade }, index: false
      t.date :ordered_on # 空 = 曾訂過但不記得哪次
      t.integer :headcount
      t.integer :total
      t.string :source, null: false # inquiry / manual
      t.text :note

      t.timestamps
    end

    add_index :order_records, :order_inquiry_id, unique: true, where: "order_inquiry_id IS NOT NULL",
      name: "index_order_records_on_order_inquiry_id_unique"
    add_check_constraint :order_records, "source IN ('inquiry', 'manual')", name: "order_records_source_values"
    add_check_constraint :order_records, "(headcount IS NULL OR headcount >= 0) AND (total IS NULL OR total >= 0)",
      name: "order_records_numbers_non_negative"
  end
end
