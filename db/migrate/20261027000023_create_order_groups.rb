class CreateOrderGroups < ActiveRecord::Migration[8.1]
  def change
    # 一場活動可同時向兩家店訂（一家餐食 + 一家飲料）：把兩張詢問單綁成一組，
    # 重開任一家都能帶出另一家，「已詢問」頁也能顯示成一組。
    create_table :order_groups do |t|
      t.references :event, null: false, foreign_key: true
      t.timestamps
    end

    # 詢問單離組（換搭檔、移除）時只是把欄位清掉，詢問單本身保留
    add_reference :order_inquiries, :order_group, null: true, foreign_key: true
  end
end
