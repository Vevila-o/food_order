import { Controller } from "@hotwired/stimulus"

// 訂單詢問產生器：複製訊息 → 標為已詢問 → 開啟店家的聯絡管道，以及儲存草稿。
//
// 順序很重要（iOS Safari）：
//   1. 在點擊事件裡「同步」呼叫 navigator.clipboard.writeText（等它完成才跳轉）
//   2. 複製成功才標為已詢問：fetch 不 await，用 keepalive，跳轉後請求仍會送完
//   3. 最後 window.location.href 開啟連結
// 複製失敗（沒有 https、權限被拒）：不跳轉、不標記，改為反白訊息讓使用者手動複製。
// 金額由伺服器算（Turbo Frame 即時更新），這裡不重算；表單還在更新時（pending）不讓複製，避免複製到舊的訊息。
const PENDING_MS = 3000

export default class extends Controller {
  static targets = ["form", "message", "status"]
  static values = { saveUrl: String }

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
    const { channel, href } = event.params
    if (this.pending) {
      this.show("金額更新中，請稍候再按一次")
      return
    }

    const copied = await this.copyMessage()
    if (!copied) {
      this.selectMessage()
      this.show("無法自動複製，已選取訊息，請長按後選「拷貝」，再自行開啟聯絡方式")
      return
    }

    this.show("已複製，正在開啟…")
    this.save(channel).catch(() => {}) // 不 await；失敗也不擋跳轉（只是沒標記為已詢問）
    window.location.href = href
  }

  async saveDraft() {
    if (this.pending) {
      this.show("金額更新中，請稍候再按一次")
      return
    }

    try {
      const response = await this.save(null)
      const data = await response.json()
      this.show(response.ok ? "已儲存草稿" : (data.errors || ["儲存失敗"]).join("、"))
    } catch {
      this.show("儲存失敗，請稍後再試")
    }
  }

  async copyMessage() {
    try {
      await navigator.clipboard.writeText(this.messageTarget.textContent)
      return true
    } catch {
      return false
    }
  }

  selectMessage() {
    const range = document.createRange()
    range.selectNodeContents(this.messageTarget)
    const selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange(range)
  }

  // 把目前表單的數量送到伺服器（伺服器重算金額與訊息後存成詢問單）；channel 有值時同時標為已詢問
  save(channel) {
    const body = new FormData(this.formTarget)
    if (channel) body.set("channel", channel)

    return fetch(this.saveUrlValue, {
      method: "POST",
      body,
      keepalive: true,
      headers: { "X-CSRF-Token": this.csrfToken, Accept: "application/json" }
    })
  }

  show(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }

  get csrfToken() {
    return document.querySelector("meta[name=csrf-token]")?.content
  }
}
