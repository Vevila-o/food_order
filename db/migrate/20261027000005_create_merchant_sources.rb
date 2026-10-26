class CreateMerchantSources < ActiveRecord::Migration[8.1]
  def change
    create_table :merchant_sources do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :platform, null: false # threads / instagram / google / web / manual
      t.string :url
      t.datetime :posted_at
      t.datetime :fetched_at
      t.text :raw_excerpt

      t.timestamps
    end

    add_check_constraint :merchant_sources,
      "platform IN ('threads', 'instagram', 'google', 'web', 'manual')",
      name: "merchant_sources_platform_values"
  end
end
