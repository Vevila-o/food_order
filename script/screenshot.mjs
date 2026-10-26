// 用 Chrome DevTools Protocol 做裝置模擬截圖，檢查實際畫面（版面、橫向溢出）。需要 Node 22+ 與 Google Chrome。
//
//   bin/rails server -p 3016 -d      # 先啟動開發伺服器（開發環境未設帳密時不需要登入）
//   node script/screenshot.mjs http://localhost:3016/ tmp/home-mobile.png 390 844 mobile
//   node script/screenshot.mjs http://localhost:3016/ tmp/home-desktop.png 1440 900
//
// 會印出 layout 的 scrollWidth / clientWidth：兩者不同代表頁面有橫向溢出（手機上會左右晃動）。
// 為什麼不直接用 chrome --screenshot？無頭 Chrome 的最小視窗寬度約 500px，390px 的手機畫面會被
// 用 500px 排版再裁切，看起來像內容被切掉，其實不是頁面的問題。CSP 設了 frame-ancestors 'none'，也不能用 iframe。
// 環境變數 CHROME_PATH 可指定 Chrome 位置。
import { spawn } from "node:child_process"
import { writeFileSync } from "node:fs"

const [url, out, width, height, mobile] = process.argv.slice(2)
if (!url || !out || !width || !height) {
  console.error("用法：node script/screenshot.mjs <網址> <輸出.png> <寬> <高> [mobile]")
  process.exit(1)
}

const chromePath = process.env.CHROME_PATH || "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
const port = 9300 + Math.floor(Math.random() * 500)
const chrome = spawn(chromePath, ["--headless=new", "--disable-gpu", `--remote-debugging-port=${port}`,
  `--user-data-dir=/tmp/cdp-profile-${Date.now()}`, "about:blank"], { stdio: "ignore" })
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

let targets
for (let i = 0; i < 40; i++) {
  try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break } catch {}
  await sleep(250)
}
const ws = new WebSocket(targets.find((target) => target.type === "page").webSocketDebuggerUrl)
await new Promise((resolve) => (ws.onopen = resolve))

let nextId = 0
const pending = new Map()
ws.onmessage = (message) => {
  const data = JSON.parse(message.data)
  if (data.id && pending.has(data.id)) { pending.get(data.id)(data); pending.delete(data.id) }
}
const send = (method, params = {}) => new Promise((resolve) => {
  const id = ++nextId
  pending.set(id, resolve)
  ws.send(JSON.stringify({ id, method, params }))
})

const metrics = (h) => ({ width: +width, height: h, deviceScaleFactor: 2, mobile: mobile === "mobile" })
await send("Emulation.setDeviceMetricsOverride", metrics(+height))
await send("Page.enable")
await send("Page.navigate", { url })
await sleep(2500)

const dims = (await send("Runtime.evaluate", {
  expression: "JSON.stringify({ scrollWidth: document.documentElement.scrollWidth, scrollHeight: document.documentElement.scrollHeight, clientWidth: document.documentElement.clientWidth })",
  returnByValue: true
})).result.result.value
const { scrollHeight } = JSON.parse(dims)
console.log("layout:", dims)

// 把視窗拉到整頁高度，截整頁
await send("Emulation.setDeviceMetricsOverride", metrics(Math.min(scrollHeight, 6000)))
await sleep(300)
const shot = await send("Page.captureScreenshot", { format: "png" })
writeFileSync(out, Buffer.from(shot.result.data, "base64"))

ws.close()
chrome.kill()
process.exit(0)
