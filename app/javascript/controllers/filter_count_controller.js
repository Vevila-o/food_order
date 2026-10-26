import { Controller } from "@hotwired/stimulus"

// 「更多篩選」按鈕上的條件數。按鈕在 Turbo Frame 外面，列表更新時不會跟著重新渲染，
// 所以在前端依抽屜裡勾選的欄位即時更新（伺服器第一次渲染時已經是正確的數字）。
//   data-controller="filter-count"，按鈕文字 data-filter-count-target="label"，
//   抽屜的 checkbox 加 data-filter-count-target="check"，排序 select 加 target="sort" 與 data-default-value
export default class extends Controller {
  static targets = ["label", "check", "sort"]

  update() {
    const checked = this.checkTargets.filter((input) => input.checked).length
    const sorted = this.hasSortTarget && this.sortTarget.value !== this.sortTarget.dataset.defaultValue ? 1 : 0
    const count = checked + sorted
    this.labelTarget.textContent = count > 0 ? `更多篩選 (${count})` : "更多篩選"
  }
}
