# 存取保護：HTTP Basic Auth

Ruby Jam 訂餐助手沒有註冊與帳號，但網址外流後任何人都能看到報名人數、觸發付費的 OpenAI 呼叫，
所以全站以 HTTP Basic Auth 保護（規格書 7.2 選項 1，確認項 #6 的建議）。

## 設定

| 環境變數 | 說明 |
| --- | --- |
| `ACCESS_USER` | 使用者名稱 |
| `ACCESS_PASSWORD` | 密碼，建議 `openssl rand -base64 24` 產生 |

- **正式環境**：缺任一變數時全站回 401（不是全開）。
- **開發 / 測試**：兩個變數都沒設時不驗證；在 `.env` 設定後才會驗證。
- iOS Safari 輸入一次後會記住。

## 實作

- `BasicAuthCredentialsService`：比對帳密（SHA256 後 `secure_compare`，避免洩漏長度與計時差異）。
- `ApplicationController#require_access!`：`before_action`，所有繼承它的 controller 都受保護。

## 不受保護的路徑

| 路徑 | 原因 |
| --- | --- |
| `/up` | 部署平台 health check（`Rails::HealthController`，不繼承 `ApplicationController`） |
| `/manifest`、`/service-worker` | PWA 檔案，瀏覽器抓取時不帶憑證（`Rails::PwaController`），內容無機密 |
| `/webhooks/kktix`（M3） | KKTIX 無法帶 Basic Auth，改用 `X-RubyJam-Webhook-Token` header 自行驗證 |

## 更換帳密

直接改主機的環境變數並重啟；舊的瀏覽器登入狀態會失效，需重新輸入。
