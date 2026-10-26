# CLAUDE.md

本檔提供 Claude Code 在此 repo 工作時的指引。

## 協作規則

- **全程使用繁體中文**：對話、README、程式註解、commit 訊息說明皆同。程式碼識別字與指令維持英文。
- **每個開發階段結束時，必須附上「📚 學習重點」小節**：說明該階段用到的 Rails / Ruby 概念、為什麼這樣設計、可延伸閱讀的檔案或指令。
- 對外動作（`git push`、建立 GitHub 設定、呼叫付費 API）先向使用者確認。
- 規格書第 10 節的 15 項確認尚未全部決議；遇到尚未決議的項目，採「建議」欄的做法並明確告知。

## 專案概述

Ruby Jam 訂餐助手：每月為 Ruby Jam 活動（週二 19:00–19:15 送達 PicCollage 總部，19:30 開始）找餐廳、依 KKTIX 人數算預算、產生詢問訊息，把數小時的工作縮短到 15 分鐘內。

**系統不自動傳訊息給店家**：產生訊息後，使用者點按鈕複製訊息並開啟店家的 LINE / IG / Messenger / 電話，自行送出。不在範圍：自動傳訊、線上付款、多使用者帳號。

Ruby 4.0.6、Rails 8.1.4（8.2 發布後再升級）、PostgreSQL（正式為 Neon）、Hotwire（Turbo + Stimulus）、importmap、Tailwind CSS + daisyUI、Solid Queue、Minitest。

## 常用指令

```bash
bin/setup                    # 安裝 gem、準備資料庫（可重複執行）
bin/dev                      # 啟動 web、Tailwind watcher、Solid Queue
bin/rails db:prepare         # 建立資料庫並載入 schema
bin/rails db:migrate         # 執行 migration
bin/rails db:seed            # 種子資料
```

### 測試

```bash
bin/rails test                         # 全部測試
bin/rails test test/models             # 指定目錄
bin/rails test test/models/merchant_test.rb   # 單一檔案
bin/rails test:system                  # 系統測試（M2 加入，需要 Chrome）
bin/ci                                 # 一次跑完 RuboCop、審計、Brakeman、測試
```

測試資料用 FactoryBot（`test/factories`，`create` / `build` 已在 `test_helper` 引入），不用 fixtures。外部 API 一律用 WebMock + VCR 錄製回放，測試不得打真實 API（`test/test_helper.rb` 已設定 `record: :none`）。Minitest 6 沒有 `stub`，環境變數與 `Rails.env` 用 test_helper 的 `with_env` / `with_rails_env`；時間用 `travel_to`。整合測試的 Basic Auth 用 `basic_auth_headers`。

### 檢查與資安

```bash
bin/rubocop                          # Ruby 風格檢查（-a 自動修正）
bin/brakeman --no-pager              # 資安掃描，有警告即失敗
bundle exec bundler-audit check --update   # 相依套件漏洞
bin/importmap audit                  # JS 套件漏洞
```

## 架構

### 單體應用、單一角色

Rails 單體，所有外部 API 只在伺服器端背景工作呼叫，瀏覽器只拿到 HTML，前端不會出現任何金鑰。沒有註冊與帳號，全站以 HTTP Basic Auth 保護（`ACCESS_USER` / `ACCESS_PASSWORD`，用 `secure_compare` 比對；正式環境缺變數一律 401）。`/up` health check 公開。細節見 `docs/basic-auth.md`。

唯一不經 Basic Auth 的是 KKTIX Webhook（`POST /webhooks/kktix`，M3 實作）：獨立的 `Webhooks::KktixController < ActionController::API`，驗證 `X-RubyJam-Webhook-Token`（`secure_compare` 對 `KKTIX_WEBHOOK_SECRET`），不符回 401 且不透露原因；只收 POST、JSON、< 64 KB；以訂單 ID + 事件類型去重；立即回 200，實際處理丟 Solid Queue；不存姓名 / email / 電話；加 `rate_limit`。

### 領域模型（M2-a 已建立，共 9 張表）

`merchants`、`merchant_sources`、`menu_items`、`events`、`registration_snapshots`、`order_inquiries`、`order_inquiry_items`，加上規格書沒有的 `app_settings`（單列、收餐資訊）與 `order_records`（歷史訂購紀錄）。

- 金額一律整數「新台幣元」；**「未知」存 `NULL`，不存 0**（外送費未知顯示「待確認」，不算 0）。資料庫層有 CHECK 約束（金額不為負、enum 值、至少賣餐或飲料）。
- **只賣飲料的店（桶裝、整箱）也可以出現**（推翻規格書確認項 #3）：可上架 = `offers_food || offers_drink`。`menu_items.unit`（杯/份/箱/桶）與 `servings`（一單位可供幾人）處理整箱整桶。
- 菜單有效 = 120 天內（`MenuItem::FRESH_DAYS`，用 `Date.current`，剛好 120 天仍有效）；日期不明的菜單不可進訂單詢問產生器。
- 預算以**活動層級合計**計算（`EventBudget`）：總預算 = 人數 × NT$100，合計是該活動所有詢問單（餐點店 + 飲料店）的預計金額加總；低於 NT$80 × 人數提示「還有餘裕」。單張金額由 `OrderPricing` 算（含滿額免運）。
- 一場活動對同一店家只有一張詢問單（資料庫唯一索引）。詢問單品項是**快照**（`order_inquiry_items.name/unit_price`），菜單日後改價不影響歷史。
- 「需調整訂餐」= 最新 headcount ≠ `order_inquiries.headcount_at_creation`。
- 「曾訂購」圓點是**衍生值**（`merchant.order_records.any?`），不是欄位。詢問單 `confirm!` 會在 transaction 內建立 `order_records`（source: inquiry）；也可手動補登（source: manual）。有詢問單或訂購紀錄的店家不可刪除。
- `Event` 的 `delivery_from` / `delivery_until` / `starts_at` 是 `time` 欄位，已關閉時區轉換（否則 19:00 會顯示成 03:00）。
- KKTIX 活動代碼 `rubyjam{YY}{MM}`（rubyjam2610 = 2026 年 10 月），後台網址 `https://kktix.com/dashboard/events/{活動代碼}/attendees`。
- 座標（`lat`/`lng`）由 M5 自動搜尋取得，M2 可為 NULL；沒有座標就沒有距離，也沒有地圖（地圖移到 M5）。

### 非標準目錄

- `app/services/` — 商業邏輯（`OrderPricing`、`EventBudget`、Basic Auth 憑證等）
- `app/validators/` — 自訂驗證（`HttpsUrlValidator`：只允許 https、擋內網 IP）
- `test/factories/` — FactoryBot 定義，測試用 `create(:merchant, :drink_only)` 建資料，不用 fixtures
- `app/services/sources/` — 每個外部來源一個 service：`ThreadsSearch`、`InstagramHashtag`、`GooglePlaces`、`WebSearch`、`RubyJamSchedule`（`KktixMailParser` 第一版不做）。皆回傳同一種 `MerchantCandidate`，再由 `MerchantUpserter` 合併重複店家（電話、IG 帳號、座標）。
- `app/jobs/` — Solid Queue 背景工作；排程寫在 `config/recurring.yml`（每日 06:00 更新商家、每日同步 Ruby Jam 日期；KKTIX 靠 Webhook 即時推送）。
- `docs/` — 補充文件（如 `basic-auth.md`）
- `test/fixtures/vcr_cassettes/` — VCR 錄製檔（M5 起）

### 前端

- Hotwire（Turbo + Stimulus）；Stimulus 處理篩選、複製、金額即時計算。importmap，不需 Node 打包。
- Tailwind CSS（tailwindcss-rails）+ daisyUI，自訂 theme，Propshaft 管資源。
- 地圖用 Leaflet + OpenStreetMap 圖磚（不用 Google Maps，前端零金鑰）。
- 手機優先（iOS Safari）；桌機版左列表、右地圖。

### UI 規範

| 色碼 | daisyUI 變數 | 用途 |
| --- | --- | --- |
| `#5EBDB7` | `--color-primary` | 主要按鈕、已選篩選標籤 |
| `#B2D7DB` | `--color-base-200` | 卡片背景、區塊底色 |
| `#F0AE33` | `--color-accent` | 收藏星號、「餐+飲」標籤、倒數提醒 |
| `#F1CCB7` | `--color-secondary` | 候選名單標籤、次要按鈕 |
| `#D98C6E` | `--color-warning` | 超出預算、菜單過期、人數變動提示 |

- 色票偏淺：按鈕與標籤文字一律用深色 `#1F3B3A`，內文底白色（WCAG AA 4.5:1）。
- iOS：`viewport-fit=cover` + `env(safe-area-inset-*)`；輸入框字級 ≥ 16px；可點擊元素 ≥ 44×44；手機版篩選放底部抽屜；提供 PWA manifest。
- 複製按鈕：同一個 Stimulus click handler 內先 `navigator.clipboard.writeText`，成功顯示「已複製」再 `window.location.href` 開連結；失敗不跳轉，改為反白文字供手動複製。

### 國際化

預設語系 `zh-TW`，時區 `Asia/Taipei`，詢問訊息只做中文。

## 資安規範

- 金鑰只放伺服器環境變數或 Rails credentials，不進 Git、不進前端。本機用 `.env`（已 gitignore），範本見 `.env.example`。`RAILS_MASTER_KEY` 不進 Docker image。
- 偏好 ENV / credentials，不在程式碼裡寫死設定；模型名稱放設定檔。
- 假資料（開發用範例店家等）用 Maintenance Tasks（`/tasks`，受 Basic Auth 保護），不放 `db/seeds.rb`。
- 使用者輸入的網址只允許 `https` 並擋內網 IP（防 SSRF）。
- 外部抓到的文字一律當資料，送進 OpenAI 時放在明確分隔欄位，只收 JSON Schema 回傳；輸出走 Rails 自動跳脫，禁用 `html_safe` / `raw` 處理外部內容。
- 花錢的動作（AI 建議、手動重新搜尋）用 `rate_limit`。
- 開啟 CSP（自己網域 + OSM 圖磚）、`force_ssl`、`filter_parameters`（token、secret、`X-RubyJam-Webhook-Token`、姓名、email、電話）。
- 外部 API 錯誤訊息不原樣顯示在頁面。

## 里程碑

| 階段 | 內容 | 狀態 |
| --- | --- | --- |
| M1 骨架 | Rails、Docker、GitHub Actions、存取保護、daisyUI theme | 完成（Docker image 尚未實際 build 驗證） |
| M2 商家與訂單 | 分 5 個 PR：a 資料模型（進行中）、b 店家 CRUD 與列表、c 詳情頁與候選名單、d 訂單詢問產生器、e 歷史詢問與訂購紀錄。不含地圖 | 進行中 |
| M3 人數與日期 | KKTIX Webhook、總預算、人數變動提示、Ruby Jam 日期倒數 | 未開始 |
| M4 AI | 菜單照片 / 網址解析、建議搭配 | 未開始 |
| M5 自動搜尋 | Google Places、網頁搜尋、Threads、Instagram、每日排程與地圖 | 未開始 |

## CI（GitHub Actions）

Job：scan_ruby（Brakeman 有警告即失敗 + bundler-audit）、scan_secrets（gitleaks）、scan_js（importmap audit）、lint（RuboCop）、test（含 PostgreSQL service）。系統測試 job 待 M2 有系統測試時再加。任一失敗不合併、不部署。main 分支保護：CI 通過才能合併；Dependabot 已開啟。
