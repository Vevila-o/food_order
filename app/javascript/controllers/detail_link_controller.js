import { Controller } from "@hotwired/stimulus"

// 店家詳情連結：桌機開新分頁（規格書），手機同分頁。
// iOS「加入主畫面」的獨立視窗中 target=_blank 會跳出到 Safari，所以獨立模式也維持同分頁。
// 沒有 JavaScript 時就是一般連結（同分頁）。
export default class extends Controller {
  connect() {
    const desktop = window.matchMedia("(min-width: 768px)").matches
    const standalone = window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true

    if (desktop && !standalone) {
      this.element.target = "_blank"
      this.element.rel = "noopener noreferrer"
    }
  }
}
