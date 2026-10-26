class AddMessageEditedToOrderInquiries < ActiveRecord::Migration[8.1]
  def change
    # 使用者在產生器手動改過訊息（message_text 是改過的版本，不是自動產生的）。
    # 只用 add_column：有資料的表不要加外鍵 / 改欄位（SQLite 會重建整張表，見 CLAUDE.md）
    add_column :order_inquiries, :message_edited, :boolean, default: false, null: false
  end
end
