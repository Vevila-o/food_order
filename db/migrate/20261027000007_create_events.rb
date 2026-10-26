class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :title, null: false
      # 活動代碼規則 rubyjam{YY}{MM}，例如 rubyjam2610
      t.string :kktix_slug, null: false
      t.date :held_on, null: false
      t.time :delivery_from, null: false, default: "19:00:00"
      t.time :delivery_until, null: false, default: "19:15:00"
      t.time :starts_at, null: false, default: "19:30:00"
      t.string :github_item_id

      t.timestamps
    end

    add_index :events, :kktix_slug, unique: true
    add_index :events, :held_on
  end
end
