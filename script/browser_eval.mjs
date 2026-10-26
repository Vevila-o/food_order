// 在真實瀏覽器（headless Chrome + DevTools Protocol）裡操作頁面，驗證 Turbo / Stimulus 的行為。
// 請求測試看不到這些：是否整頁重載、frame 更新、剪貼簿、跳轉。
//
// 用法：node script/browser_eval.mjs <網址> <腳本.js> [寬 高 mobile|desktop] [截圖.png]
//   腳本是一個會回傳物件的 async 表達式：(async () => { ...; return { 結果 } })()，回傳值會印成 JSON。
//   會授權剪貼簿並模擬視窗焦點（headless 預設沒有焦點，clipboard 會被拒）。
//   頁面要求的導覽網址（例如 window.location.href = "https://line.me/..."）會列在「導覽要求」。
//   需要先啟動 bin/dev；不要在腳本裡操作正式環境。
import { spawn } from "node:child_process"
import { readFileSync, writeFileSync } from "node:fs"
const [url, scriptPath, w = "390", h = "844", mobile = "mobile", shot] = process.argv.slice(2)
const port = 9400 + Math.floor(Math.random() * 300)
const chrome = spawn("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  ["--headless=new", "--disable-gpu", `--remote-debugging-port=${port}`, "--user-data-dir=/tmp/cdp-e2e-" + Date.now(), "about:blank"], { stdio: "ignore" })
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
let targets
for (let i = 0; i < 40; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break } catch {} await sleep(250) }
const ws = new WebSocket(targets.find((t) => t.type === "page").webSocketDebuggerUrl)
await new Promise((r) => (ws.onopen = r))
let id = 0; const pending = new Map(); const navs = []
ws.onmessage = (m) => { const d = JSON.parse(m.data); if (d.id && pending.has(d.id)) { pending.get(d.id)(d); pending.delete(d.id) } else if (d.method === "Page.frameRequestedNavigation") navs.push(d.params.url) }
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })) })
const origin = new URL(url).origin
await send("Browser.grantPermissions", { origin, permissions: ["clipboardReadWrite", "clipboardSanitizedWrite"] })
await send("Emulation.setDeviceMetricsOverride", { width: +w, height: +h, deviceScaleFactor: 2, mobile: mobile === "mobile" })
await send("Page.enable"); await send("Emulation.setFocusEmulationEnabled", { enabled: true })
await send("Page.navigate", { url })
await sleep(2500)
const res = await send("Runtime.evaluate", { expression: readFileSync(scriptPath, "utf8"), returnByValue: true, awaitPromise: true })
console.log(JSON.stringify(res.result.result.value ?? res.result.exceptionDetails ?? res.result, null, 1))
console.log("導覽要求:", JSON.stringify(navs))
if (shot) {
  await send("Emulation.setDeviceMetricsOverride", { width: +w, height: 1700, deviceScaleFactor: 2, mobile: mobile === "mobile" })
  await sleep(300)
  writeFileSync(shot, Buffer.from((await send("Page.captureScreenshot", { format: "png" })).result.data, "base64"))
}
ws.close(); chrome.kill(); process.exit(0)
