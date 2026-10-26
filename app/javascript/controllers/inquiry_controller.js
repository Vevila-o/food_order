import { Controller } from "@hotwired/stimulus"

// 訂單詢問產生器：複製訊息 → 標為已詢問 → 開啟店家的聯絡管道、儲存草稿、挑選 / 重置搭配的另一家。
//
// 順序很重要（iOS Safari）：
//   1. 在點擊事件裡「同步」呼叫 navigator.clipboard.writeText（等它完成才跳轉）
//   2. 複製成功才標為已詢問：fetch 不 await，用 keepalive，跳轉後請求仍會送完
//   3. 最後 window.location.href 開啟連結
// 複製失敗（沒有 https、權限被拒）：不跳轉、不標記，改為反白訊息讓使用者手動複製。
// 配對兩家時畫面上有兩則訊息、兩組聯絡按鈕：每顆按鈕用 data-inquiry-message-id-param 指到「自己那一則」，
// data-inquiry-merchant-id-param 指到被標為已詢問的店家。
// 金額由伺服器算（Turbo Frame 即時更新），這裡不重算；表單還在更新時（pending）不讓複製，避免複製到舊的訊息。
const PENDING_MS = 3000

export default class extends Controller {
  static targets = ["form", "draftStatus"]
  static values = { saveUrl: String, partnerUrl: String }

  connect() {
    this.pendingUntil = 0
  }

  // 表單有輸入：到下一次 frame 載入完成前，視為「金額更新中」（最多 3 秒，避免請求失敗時卡死）
  markPending() {
    this.pendingUntil = Date.now() + PENDING_MS
  }

  ready() {
    this.pendingUntil = 0
  }

  get pending() {
    return Date.now() < this.pendingUntil
  }

  async contact(event) {
    const { channel, href, messageId, merchantId } = event.params
    const status = this.statusNear(event.currentTarget)
    const message = document.getElementById(messageId)
    if (this.pending) {
      this.show(status, "金額更新中，請稍候再按一次")
      return
    }

    const copied = await this.copy(message)
    if (!copied) {
      this.select(message)
      this.show(status, "無法自動複製，已選取訊息，請長按後選「拷貝」，再自行開啟聯絡方式")
      return
    }

    this.show(status, "已複製，正在開啟…")
    this.save(channel, merchantId).catch(() => {}) // 不 await；失敗也不擋跳轉（只是沒標記為已詢問）
    window.location.href = href
  }

  async saveDraft() {
    if (this.pending) {
      this.show(this.draftStatusTarget, "金額更新中，請稍候再按一次")
      return
    }

    try {
      const response = await this.save(null, null)
      const data = await response.json()
      this.show(this.draftStatusTarget, response.ok ? "已儲存草稿" : (data.errors || ["儲存失敗"]).join("、"))
    } catch {
      this.show(this.draftStatusTarget, "儲存失敗，請稍後再試")
    }
  }

  // 右側面板的「選這家」：帶著目前表單的數量與 partner_id 重新載入產生器（離散的一次性動作，整頁換）
  pickPartner(event) {
    this.visitWith(event.params.partnerId)
  }

  // 重置：這間店離組、只算目前這一家（保留目前這間店填的數量）
  async resetPartner() {
    try {
      await fetch(this.partnerUrlValue, { method: "DELETE", headers: { "X-CSRF-Token": this.csrfToken } })
    } catch {
      // 離組失敗也照樣只算這一家（只是下次打開可能又帶出搭檔）
    }
    this.visitWith("")
  }

  visitWith(partnerId) {
    const params = new URLSearchParams(new FormData(this.formTarget))
    params.set("partner_id", partnerId)
    const url = `${location.pathname}?${params.toString()}`
    window.Turbo ? window.Turbo.visit(url, { action: "replace" }) : (window.location.href = url)
  }

  async copy(element) {
    try {
      await navigator.clipboard.writeText(element.textContent)
      return true
    } catch {
      return false
    }
  }

  select(element) {
    const range = document.createRange()
    range.selectNodeContents(element)
    const selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange(range)
  }

  // 把目前表單的數量送到伺服器（伺服器重算金額與訊息後存成詢問單）；channel 有值時把 merchantId 那一家標為已詢問
  save(channel, merchantId) {
    const body = new FormData(this.formTarget)
    if (channel) body.set("channel", channel)
    if (merchantId) body.set("contact_merchant_id", merchantId)

    return fetch(this.saveUrlValue, {
      method: "POST",
      body,
      keepalive: true,
      headers: { "X-CSRF-Token": this.csrfToken, Accept: "application/json" }
    })
  }

  // 按鈕所在區塊的狀態文字（兩家時各自顯示在自己的區塊）
  statusNear(button) {
    return button.closest("section")?.querySelector("[data-inquiry-status]")
  }

  show(element, text) {
    if (element) element.textContent = text
  }

  get csrfToken() {
    return document.querySelector("meta[name=csrf-token]")?.content
  }
}
