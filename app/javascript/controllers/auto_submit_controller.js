import { Controller } from "@hotwired/stimulus"

// 表單內容改變就自動送出（桌機側欄的篩選）。短暫延遲，連續勾選只送一次。
//   <form data-controller="auto-submit" data-action="change->auto-submit#submit">
export default class extends Controller {
  static values = { delay: { type: Number, default: 150 } }

  submit() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
