class MerchantSource < ApplicationRecord
  belongs_to :merchant
  has_many :menu_items, foreign_key: :source_id, inverse_of: :source, dependent: :nullify

  enum :platform, { threads: "threads", instagram: "instagram", google: "google", web: "web", manual: "manual" },
    prefix: true, validate: true

  validates :url, https_url: true
end
