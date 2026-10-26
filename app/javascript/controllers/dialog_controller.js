import { Controller } from "@hotwired/stimulus"

// 開關 <dialog>（手機版底部篩選抽屜）。<dialog> 原生就有焦點管理、Esc 關閉與背景遮罩。
//   data-controller="dialog"，按鈕 data-action="dialog#open"，<dialog data-dialog-target="dialog">
export default class extends Controller {
  static targets = ["dialog"]

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    if (this.hasDialogTarget && this.dialogTarget.open) this.dialogTarget.close()
  }
}
