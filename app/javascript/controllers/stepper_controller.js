import { Controller } from "@hotwired/stimulus"

// 數量的 −／＋／「＝ 人數」按鈕（StepperComponent）。改值後送出 input 事件（會冒泡），
// 外層表單的 auto-submit 與 inquiry controller 都聽這個事件。
export default class extends Controller {
  static targets = ["input"]
  static values = { max: { type: Number, default: 99 }, headcount: Number }

  increment() {
    this.set(this.current + 1)
  }

  decrement() {
    this.set(this.current - 1)
  }

  fill() {
    this.set(this.headcountValue)
  }

  get current() {
    const number = parseInt(this.inputTarget.value, 10)
    return Number.isNaN(number) ? 0 : number
  }

  set(value) {
    this.inputTarget.value = Math.min(this.maxValue, Math.max(0, value))
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
