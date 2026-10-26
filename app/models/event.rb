class Event < ApplicationRecord
  PER_PERSON_BUDGET = 100 # 總預算一律以 NT$100 × 人數計算
  MIN_PER_PERSON = 80     # 低於 NT$80 × 人數提示「還有餘裕」
  WEEKDAYS = %w[日 一 二 三 四 五 六].freeze

  # 這三個欄位是「當天的幾點幾分」，不是時間點：不做時區轉換，否則 19:00 會被當成 UTC 而顯示成 03:00
  self.skip_time_zone_conversion_for_attributes = [ :delivery_from, :delivery_until, :starts_at ]

  has_many :registration_snapshots, dependent: :destroy
  has_many :order_inquiries, dependent: :destroy
  has_many :order_records, dependent: :nullify

  before_validation :assign_defaults

  validates :held_on, presence: true
  validates :title, :kktix_slug, presence: true
  validates :kktix_slug, uniqueness: true

  scope :latest_first, -> { order(held_on: :desc) }

  # 目前要處理的活動：最近一場還沒舉行（含今天）的；都已過去則取最近一場
  def self.current
    where(held_on: Date.current..).order(:held_on).first || latest_first.first
  end

  # 目前人數 = 最新一筆快照（Webhook 或手動修正）；沒有任何快照時為 nil
  def headcount
    latest_snapshot&.headcount
  end

  def latest_snapshot
    registration_snapshots.order(received_at: :desc, id: :desc).first
  end

  def total_budget = headcount && headcount * PER_PERSON_BUDGET

  def min_budget = headcount && headcount * MIN_PER_PERSON

  # 活動代碼規則 rubyjam{YY}{MM}（rubyjam2610 = 2026 年 10 月），可手動修改
  def self.slug_for(date) = "rubyjam#{date.strftime("%y%m")}"

  def self.title_for(date) = "Ruby Jam #{date.year} 年 #{date.month} 月"

  # 新增活動時預設的日期：今天起算的下一個週二（今天就是週二則是今天）。Ruby Jam 通常在週二，但實際日期以使用者填的為準
  def self.default_date(today = Date.current) = today + ((2 - today.wday) % 7)

  def kktix_attendees_url = "https://kktix.com/dashboard/events/#{kktix_slug}/attendees"

  # 「週二」由日期計算，不寫死
  def weekday_label = "週#{WEEKDAYS[held_on.wday]}"

  def delivery_window_label = "#{delivery_from.strftime("%H:%M")}–#{delivery_until.strftime("%H:%M")}"

  private

  def assign_defaults
    return unless held_on

    self.kktix_slug = self.class.slug_for(held_on) if kktix_slug.blank?
    self.title = self.class.title_for(held_on) if title.blank?
  end
end
