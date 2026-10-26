class CreateOrderInquiries < ActiveRecord::Migration[8.1]
  def change
    create_table :order_inquiries do |t|
      t.references :event, null: false, foreign_key: true
      # 有詢問單 / 訂購紀錄的店家不可刪除（歷史不能斷）
      t.references :merchant, null: false, foreign_key: { on_delete: :restrict }
      t.integer :headcount_at_creation, null: false
      t.integer :subtotal, null: false
      t.integer :delivery_fee # 未知存 NULL，不存 0
      t.integer :total        # 外送費未知時為 NULL（顯示「待確認」）
      t.text :message_text
      t.string :status, null: false, default: "draft" # draft / sent / confirmed
      t.string :contacted_via # line / instagram / messenger / phone
      t.datetime :sent_at

      t.timestamps
    end

    # 一場活動對同一店家只有一張詢問單（重新產生會覆蓋）
    add_index :order_inquiries, [ :event_id, :merchant_id ], unique: true
    add_check_constraint :order_inquiries, "status IN ('draft', 'sent', 'confirmed')", name: "order_inquiries_status_values"
    add_check_constraint :order_inquiries,
      "contacted_via IS NULL OR contacted_via IN ('line', 'instagram', 'messenger', 'phone')",
      name: "order_inquiries_contacted_via_values"
    add_check_constraint :order_inquiries,
      "subtotal >= 0 AND (delivery_fee IS NULL OR delivery_fee >= 0) AND (total IS NULL OR total >= 0)",
      name: "order_inquiries_money_non_negative"
  end
end
