# 活動設定表單：活動日期、KKTIX 活動代碼，加上「手動修正報名人數」。
# 人數不是 events 的欄位（人數是 registration_snapshots 的時間序列），所以用表單物件把兩件事包在同一個 transaction：
# 儲存活動 → 人數有改才新增一筆 source: manual 的快照（保留修正紀錄，M3 起 Webhook 會寫入更新的快照）。
class EventForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :held_on, :date
  attribute :kktix_slug, :string
  # 字串形式接收：整數欄位會把「abc」「1.5」默默轉成 nil / 1，使用者以為存了其實沒有
  attribute :headcount, :string

  attr_reader :event

  # 讓 form_with 的欄位名稱是 event[...]、錯誤訊息與標籤沿用「活動」的翻譯
  def self.model_name = ActiveModel::Name.new(self, nil, "Event")

  validates :held_on, presence: true
  validates :headcount, format: { with: /\A\d{1,3}\z/, message: "必須是 0 到 999 的整數" }, allow_blank: true

  delegate :persisted?, :to_key, :id, to: :event

  def initialize(event = Event.new, attributes = {})
    @event = event
    super(defaults_from(event).merge(attributes.to_h.symbolize_keys))
    @original_date = event.held_on
    @original_slug = event.kktix_slug
  end

  # 存檔。成功時 event 是最新狀態；失敗時錯誤都在這個物件上。
  def save
    return false unless valid?

    Event.transaction do
      event.assign_attributes(held_on: held_on, kktix_slug: slug_to_save, title: title_to_save)
      event.save!
      record_headcount if headcount_changed?
    end
    true
  rescue ActiveRecord::RecordInvalid
    event.errors.each { |error| errors.add(error.attribute, error.message) }
    false
  end

  # 活動日期不是週二：不擋，存檔後提醒（Ruby Jam 通常在週二）
  def unusual_weekday? = held_on.present? && !held_on.tuesday?

  private

  def defaults_from(event)
    {
      held_on: event.held_on || Event.default_date,
      kktix_slug: event.kktix_slug,
      headcount: event.headcount&.to_s
    }
  end

  # 日期改了、而代碼還是舊日期自動產生的那個：重新產生，否則代碼會停在舊月份
  def slug_to_save
    return if kktix_slug.blank?
    return if @original_date && kktix_slug == Event.slug_for(@original_date) && held_on != @original_date

    kktix_slug.strip
  end

  def title_to_save
    return event.title if event.title.blank? || !@original_date || held_on == @original_date
    return Event.title_for(held_on) if event.title == Event.title_for(@original_date)

    event.title
  end

  # 沒有填、或和目前一樣就不新增快照
  def headcount_value = headcount.presence&.to_i

  def headcount_changed? = headcount_value && headcount_value != event.headcount

  def record_headcount
    event.registration_snapshots.create!(headcount: headcount_value, source: "manual")
  end
end
