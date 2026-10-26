class CreateRegistrationSnapshots < ActiveRecord::Migration[8.1]
  def change
    # 只存人數與時間，不存報名者姓名、email
    create_table :registration_snapshots do |t|
      t.references :event, null: false, foreign_key: true
      t.integer :headcount, null: false
      t.string :source, null: false # webhook / manual
      t.datetime :received_at, null: false
      t.string :kktix_order_id
      t.string :kktix_event_type

      t.timestamps
    end

    # 訂單 ID + 事件類型去重：Webhook 重送不重複計算（手動修正沒有訂單 ID，不受限）
    add_index :registration_snapshots, [ :event_id, :kktix_order_id, :kktix_event_type ],
      unique: true, where: "kktix_order_id IS NOT NULL", name: "index_registration_snapshots_dedupe"
    add_index :registration_snapshots, [ :event_id, :received_at ]
    add_check_constraint :registration_snapshots, "headcount >= 0", name: "registration_snapshots_headcount_non_negative"
    add_check_constraint :registration_snapshots, "source IN ('webhook', 'manual')", name: "registration_snapshots_source_values"
  end
end
