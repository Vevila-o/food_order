import { Controller } from "@hotwired/stimulus"

// 巢狀表單：動態新增 / 移除列（菜單項目、來源網址）。
// 用法：data-controller="nested-form"，內含
//   <template data-nested-form-target="template">…NEW_RECORD…</template>
//   <div data-nested-form-target="container">已有的列</div>
//   按鈕 data-action="nested-form#add" / "nested-form#remove"，每列加 data-nested-form-row
export default class extends Controller {
  static targets = ["template", "container"]

  add(event) {
    event.preventDefault()
    const uid = `${Date.now()}${Math.floor(Math.random() * 1000)}`
    this.containerTarget.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML.replaceAll("NEW_RECORD", uid))
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-nested-form-row]")
    const destroy = row.querySelector("input[name$='[_destroy]']")
    if (destroy) {
      // 已存在的紀錄：標記刪除並隱藏，送出表單時才真的刪
      destroy.value = "1"
      row.hidden = true
    } else {
      row.remove()
    }
  }
}
