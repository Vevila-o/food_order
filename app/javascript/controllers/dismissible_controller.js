import { Controller } from "@hotwired/stimulus"

// 關掉提示框（只在這次瀏覽有效，不存任何東西，重新整理會再出現）。
//   <div data-controller="dismissible"> ... <button data-action="dismissible#dismiss">
export default class extends Controller {
  dismiss() {
    this.element.remove()
  }
}
