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

Ruby 4.0.6、Rails 8.1.4（8.2 發布後再升級）、SQLite、Hotwire（Turbo + Stimulus）、importmap、Tailwind CSS + daisyUI、Solid Queue、Minitest。

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

### 資料庫：SQLite（開發、測試、正式皆同）

使用者決定用 SQLite，**推翻規格書的 PostgreSQL / Neon**（確認項 #7 原本建議 PostgreSQL）。
- 資料庫檔在 `storage/`。正式環境依 Rails 8 預設分成 4 個檔：`production`（主）、`production_cache`、`production_queue`（Solid Queue）、`production_cable`；Solid 三組各有 `db/*_schema.rb`，主庫的 migration 只放業務表。
- SQLite 同時只有一個寫入者：正式環境只跑單一容器；`/rails/storage` 必須掛持久磁碟並備份（見 README）。
- 寫 migration / 查詢時注意跨資料庫行為：用 `NULLS LAST` 明確指定 NULL 排序、`add_check_constraint` 與部分唯一索引（`where:`）SQLite 都支援。不要用 PostgreSQL 專屬功能（陣列、jsonb 運算子、`ILIKE`）。

### 單體應用、單一角色

Rails 單體，所有外部 API 只在伺服器端背景工作呼叫，瀏覽器只拿到 HTML，前端不會出現任何金鑰。沒有註冊與帳號，全站以 HTTP Basic Auth 保護（`ACCESS_USER` / `ACCESS_PASSWORD`，用 `secure_compare` 比對；正式環境缺變數一律 401）。`/up` health check 公開。細節見 `docs/basic-auth.md`。

唯一不經 Basic Auth 的是 KKTIX Webhook（`POST /webhooks/kktix`，M3 實作）：獨立的 `Webhooks::KktixController < ActionController::API`，驗證 `X-RubyJam-Webhook-Token`（`secure_compare` 對 `KKTIX_WEBHOOK_SECRET`），不符回 401 且不透露原因；只收 POST、JSON、< 64 KB；以訂單 ID + 事件類型去重；立即回 200，實際處理丟 Solid Queue；不存姓名 / email / 電話；加 `rate_limit`。

### 領域模型（共 10 張表）

`merchants`、`merchant_sources`、`menu_items`、`events`、`registration_snapshots`、`order_inquiries`、`order_inquiry_items`，加上規格書沒有的 `order_groups`（兩家配對訂購綁成一組）、`app_settings`（單列、收餐資訊）與 `order_records`（歷史訂購紀錄）。

- 金額一律整數「新台幣元」；**「未知」存 `NULL`，不存 0**（外送費未知顯示「待確認」，不算 0）。資料庫層有 CHECK 約束（金額不為負、enum 值、至少賣餐或飲料）。
- **只賣飲料的店（桶裝、整箱）也可以出現**（推翻規格書確認項 #3）：可上架 = `offers_food || offers_drink`。`menu_items.unit`（杯/份/箱/桶）與 `servings`（一單位可供幾人）處理整箱整桶。
- 菜單有效 = 120 天內（`MenuItem::FRESH_DAYS`，用 `Date.current`，剛好 120 天仍有效）；日期不明的菜單不可進訂單詢問產生器。
- 預算以 `EventBudget` 計算：總預算 = 人數 × NT$100，合計是目前這一家或配對的兩家（餐點店 + 飲料店）的預計金額加總（產生器不把本場其他詢問單算進來）；低於 NT$80 × 人數提示「還有餘裕」。單張金額由 `OrderPricing` 算（含滿額免運）。
- 一場活動對同一店家只有一張詢問單（資料庫唯一索引）。詢問單品項是**快照**（`order_inquiry_items.name/unit_price`），菜單日後改價不影響歷史。
- 「需調整訂餐」= 最新 headcount ≠ `order_inquiries.headcount_at_creation`。
- 「曾訂購」圓點是**衍生值**（`merchant.order_records.any?`），不是欄位。詢問單 `confirm!` 會在 transaction 內建立 `order_records`（source: inquiry）；也可手動補登（source: manual）。有詢問單或訂購紀錄的店家不可刪除。
- `Event` 的 `delivery_from` / `delivery_until` / `starts_at` 是 `time` 欄位，已關閉時區轉換（否則 19:00 會顯示成 03:00）。
- KKTIX 活動代碼 `rubyjam{YY}{MM}`（rubyjam2610 = 2026 年 10 月），後台網址 `https://kktix.com/dashboard/events/{活動代碼}/attendees`。
- **瀏覽歷史**：`merchants.last_viewed_at`，打開詳情頁時 `record_view!`（`update_column`，不改 `updated_at`）；一間店只記最後一次，`Merchant.recently_viewed` 取最近 20 間。**Turbo 會在滑鼠移到連結時預先載入頁面（`X-Sec-Purpose: prefetch`），那不算瀏覽**（`MerchantsController#prefetch_request?`）。
- 座標（`lat`/`lng`）由 M5 自動搜尋取得，M2 可為 NULL；沒有座標就沒有距離，也沒有地圖（地圖移到 M5）。

### 非標準目錄

- `app/services/` — 商業邏輯（`OrderPricing`、`EventBudget`、Basic Auth 憑證等）
- `app/components/` — ViewComponent UI 元件（`PageHeader`、`MerchantCard`、`FilterBar`、`EventSummary`、`Pill`、`Icon`、`EmptyState`、`Field` 等**大塊、會重複使用或有獨立行為（要測試）的共用 UI 做成元件**，不用 helper / partial；只出現一次的小片段（一個標題加一段文字、單頁專用的列表列）留在 view，不必每塊都拆）。每個元件必須在 `test/components/previews/` 有 Lookbook 預覽，並有 `test/components/*_test.rb`；`PreviewsTest` 會檢查「每個元件都有預覽」與「所有預覽都能渲染」。預覽用的假資料見 `PreviewMerchants`（只在記憶體建立，不寫資料庫）。
- `app/helpers/` — 只放純文字格式化（`enum_text`、`format_money`、`delivery_fee_text` 等），不放 UI 標記
- `app/services/merchant_filter.rb` — 首頁篩選與排序（網址 `filter[kinds][]`（可複選，OR）、`filter[sort]`、`filter[<旗標>]=1`）。規則：19:00 外送「待確認也顯示」；每人 ≤ NT$100「估價沒填仍顯示」；免外送費「只算外送費明確為 0 或滿額門檻 ≤ 本場預算，未知不算」；預設排序收藏優先再依最近更新。不認得的參數值一律忽略。controller 用 `params.permit(filter: [ :sort, *FLAGS, { kinds: [] } ])[:filter].to_h`（`fetch(:filter, {})` 的預設值會變成未 permit 的 Parameters 而報錯）。
- `app/services/menu_text_parser.rb`、`app/models/menu_import.rb` — 貼上菜單：解析 → 預覽 → 確認才寫入（確認時重新解析）
- `app/controllers/merchants/` — 收藏 / 下次候選：`POST` 加入、`DELETE` 移除（冪等），Turbo Stream 只替換被按的 `ToggleButtonComponent`，沒有 JavaScript 時 redirect 回原頁。`Merchant#favorite!` / `add_to_shortlist!` / `remove_from_shortlist!` 用 `update_columns`：**不算更新店家，不改 `updated_at`**（列表依最近更新排序，按收藏不該讓順序跳動）；加入候選排在最後（最大位置 + 1），移出時清掉位置但保留備註。
- **側欄**（`SidebarComponent`）：全部店家 / 瀏覽歷史 / 收藏 / 下次訂購 / 已詢問 / 已訂購。桌機固定在左側，手機由頁首左上角選單開出 `modal-start` 抽屜（layout 外層的 `dialog` controller）；數量來自 `ApplicationHelper#sidebar_counts`（每個請求 5 次 COUNT）。對應頁面：`BrowsingHistoriesController`（`/history`）、`FavoriteMerchantsController`（`/favorites`，重用 `MerchantFilter`）、`ShortlistedMerchantsController`（`/shortlist`，下次候選的店家，依加入順序 `Merchant.shortlisted`，不套收藏優先排序；排序調整與備註在 M2-c）、`InquiriesController`（`/inquiries`）、`OrdersController`（`/orders`）。已詢問、已訂購用 `DataTableComponent`：桌機表格、手機每筆一張卡片（格子的文字會跳脫，要放連結 / 標籤請傳 html_safe）。
- **活動與設定（M2-d1）**：`EventForm`（`app/models/event_form.rb`）是表單物件，把「活動日期 / KKTIX 代碼」與「手動修正人數」包在同一個 transaction：人數不是 events 的欄位，有改才新增一筆 `registration_snapshots`（source: manual），保留修正紀錄；人數用字串接收再驗證 `\A\d{1,3}\z`（整數欄位會把「abc」默默轉成 nil）。日期改了而代碼 / 名稱還是舊日期自動產生的，會跟著重新產生；手動改過的不覆蓋。**活動日期已過、或不是週二都不擋**（下一場日期常常還不確定），只提醒。`SettingsController` 管 `AppSetting` 收餐資訊（名稱與地址至少填一個；收件人與電話選填，有填才寫進詢問訊息，會傳給每間店家），另有「發票」區的統一編號（`tax_id`，8 碼數字、選填，只檢查格式不檢查檢查碼；目前只存不寫進訊息）。活動不提供刪除（會連帶刪詢問單）。
- **訂單詢問產生器（M2-d2）**：`/merchants/:id/inquiry`（`Merchants::InquiriesController`）。`InquiryForm`（表單物件）是核心：只接受屬於該店且菜單有效（≤120 天）的品項，單價 / 品名 / 單位由伺服器從 `menu_items` 帶入，金額與訊息在伺服器重算一次（`OrderPricing`、`EventBudget`、`InquiryMessage`），**不在 JS 重寫**；畫面預覽、複製、存進 `message_text` 是同一份文字。不認得的品項 id 忽略、過期品項與非整數 / 超出 0–99 的數量回報錯誤。草稿只在「儲存草稿」或按聯絡按鈕時才寫入（試算不寫）；一場活動對一間店只有一張詢問單，再存會覆蓋（品項整批換掉），已確認訂購的不可改，已詢問的再存草稿不會降回草稿。沒有活動 / 沒有人數 → 導到設定頁說明；活動日期已過**不擋**，只顯示詢問框與訊息旁提醒。`InquiryMessage` 照規格書範本，「（週二）」由日期算，收件資訊有填才寫、地點一律寫。
- **兩家配對訂購（M2-f）**：一場活動常同時向一家餐食店 + 一家飲料店訂。`InquiryPair`（表單物件，包兩個 `InquiryForm`）負責配對規則，controller 不放商業邏輯：搭檔來自網址 `partner_id`（空字串 = 明確沒有；沒帶 = 用已存的組，**只有兩張都還是草稿才自動帶出**，已詢問過的重新打開就是乾淨的單店，從「已詢問」頁的「開啟詢問」進來才會帶 `partner_id`）；數量用扁平的 `quantities[menu_item_id]`，某家的品項沒出現在請求裡就用它已存的詢問單當預設；合計（小計、外送費、總額，任一家外送費未知就是 `nil`）與總預算比較（`EventBudget`，**只算目前這一家或配對的兩家的試算**，不含本場其他店家的詢問單——使用者明確要求，否則範例資料與其他詢問單會被加進合計）；儲存時兩家（有選品項的）一起存、綁成 `OrderGroup`，只有被按聯絡按鈕的那家標為已詢問；換搭檔 / 重置時舊詢問單保留（狀態不變）只是離組，組內不足兩張就刪組（`InquiryPair.detach!`）。右側面板（`dialog.modal-end`，懶載入 `/merchants/:id/inquiry/partners`）候選 = 賣所需類別的店（含餐＋飲），排除自己與 19:00 明確不外送，排序下次訂購 → 收藏 → 最近更新（`InquiryPair.candidates`）；兩家各自一則訊息（`inquiry-message-<店家 id>`）與聯絡按鈕，按鈕用 `data-inquiry-message-id-param` 指到自己那則。「重置，只算這家」呼叫 `DELETE /merchants/:id/inquiry/partner` 後以只有這家的網址重新載入。
- `app/validators/` — 自訂驗證（`HttpsUrlValidator`：只允許 https、擋內網 IP）
- `test/factories/` — FactoryBot 定義，測試用 `create(:merchant, :drink_only)` 建資料，不用 fixtures
- `app/services/sources/` — 每個外部來源一個 service：`ThreadsSearch`、`InstagramHashtag`、`GooglePlaces`、`WebSearch`、`RubyJamSchedule`（`KktixMailParser` 第一版不做）。皆回傳同一種 `MerchantCandidate`，再由 `MerchantUpserter` 合併重複店家（電話、IG 帳號、座標）。
- `app/jobs/` — Solid Queue 背景工作；排程寫在 `config/recurring.yml`（每日 06:00 更新商家、每日同步 Ruby Jam 日期；KKTIX 靠 Webhook 即時推送）。
- `app/tasks/maintenance/` — Maintenance Tasks（掛在 `/tasks`，`parent_controller` 已設為 `ApplicationController` 才受 Basic Auth 保護；預設是不受保護的）。範例資料 `SeedSampleDataTask` / `RemoveSampleDataTask` 呼叫 `SampleData`，店家以「【範例】」開頭，正式環境拒絕執行。其 UI 的 inline 自動重新整理 script 會被 CSP 擋掉，需手動重新整理。
- `docs/` — 補充文件（如 `basic-auth.md`）
- `test/fixtures/vcr_cassettes/` — VCR 錄製檔（M5 起）

### 前端

- **Stimulus**（`app/javascript/controllers`）：`stepper`（數量 −／＋／＝ 人數，改值後送出會冒泡的 `input` 事件）、`inquiry`（產生器：複製 → 標記 → 跳轉、儲存草稿）、`dismissible`（關掉提示框）、`nested-form`（動態新增 / 移除巢狀列）、`auto-submit`（篩選膠囊變更即送出）、`dialog`（「更多篩選」抽屜）、`filter-count`（「更多篩選」按鈕的條件數，按鈕在 Turbo Frame 外所以由前端即時更新）、`detail-link`（桌機開新分頁、手機與 iOS 獨立模式同分頁）。
- **產生器的複製與跳轉順序（iOS Safari）**：在點擊事件裡先 `await navigator.clipboard.writeText`（同步呼叫），成功才 `fetch(..., { keepalive: true })` 標為已詢問（**不 await**、帶 `X-CSRF-Token`），最後 `window.location.href`。複製失敗不跳轉、不標記，反白訊息供手動複製；金額更新中（表單剛有輸入、Turbo Frame 還沒回來，最多 3 秒）不讓複製，避免複製到舊訊息。剪貼簿需要 https 或 localhost。iPhone 真機行為仍待實測。
- **Turbo Frame**：首頁列表在 `turbo-frame#merchant-list`，篩選表單 `data-turbo-frame` 指向它並 `turbo_action: advance` 更新網址；frame 內的連結要加 `data-turbo-frame="_top"` 才會跳出 frame。
- **CSP**：不可使用 inline `style="..."`（`style-src 'self'`），要用 Tailwind class（例如 `pb-[calc(0.5rem+env(safe-area-inset-bottom))]`）。
- **ViewComponent + Lookbook**：開發環境開 http://localhost:3000/lookbook 預覽所有元件（Lookbook 只裝在 development 群組，正式環境沒有；其介面需要 inline script，所以只對 Lookbook 自己的 controller 關閉 CSP，見 `config/initializers/lookbook.rb`）。
- **ViewComponent 陷阱**：在 ERB 或預覽裡傳 block 要寫 `render(MyComponent.new(...)) { "內容" }`；寫成 `render MyComponent.new(...) { "內容" }` 時大括號會綁到 `new`，內容會默默變成空的。元件裡用 route / 自訂 helper 要加 `helpers.`（例如 `helpers.merchant_path(m)`、`helpers.format_money(n)`）。

- Hotwire（Turbo + Stimulus）；Stimulus 處理篩選、複製、金額即時計算。importmap，不需 Node 打包。
- Tailwind CSS（tailwindcss-rails）+ daisyUI，自訂 theme，Propshaft 管資源。
- 地圖用 Leaflet + OpenStreetMap 圖磚（不用 Google Maps，前端零金鑰）。
- 手機優先（iOS Safari）；桌機版左列表、右地圖。

### UI 規範

視覺依設計稿「Ruby Jam 訂餐助手 介面設計」（iOS 首頁 / 詳情 / 訂單詢問產生器、桌機首頁 四個畫板）。設計稿與規格書 8.1 不同處**以設計稿為準**：頁面底色 `#F4F9F9`、卡片白色，`#B2D7DB` 只用在活動摘要卡與「只有餐」標籤。

| 色碼 | 變數 / class | 用途 |
| --- | --- | --- |
| `#5EBDB7` | `primary` | 主要按鈕、已選膠囊 |
| `#F4F9F9` | `base-200` | 頁面底色、列表分隔 |
| `#FFFFFF` | `base-100` | 卡片、頁首 |
| `#DCEDEE` | `base-300` | 細線、邊框 |
| `#B2D7DB` | `soft` | 活動摘要卡、「只有餐」標籤、膠囊邊框 |
| `#F0AE33` | `accent` | 「餐＋飲」標籤、曾訂購圓點、建議搭配邊框 |
| `#F1CCB7` | `secondary` | 「待確認」「菜單可能過期」「僅飲料」標籤 |
| `#D98C6E` | `warning` | 超出預算、需調整訂餐提示（文字 `#2A140B`） |
| `#4E6463` | `muted` | 輔助文字（白底 6.3:1；**不要放在 `soft` 上**，只有 4.1:1） |

- 文字一律深色（`#14302F`，warning 上用 `#2A140B`），對比 ≥ 4.5:1。設計稿的 `#6A7C7B`（4.39:1）不合格，已改用 `muted`。
- 字型用系統字型（PingFang TC → Noto Sans TC → 無襯線），**不載入 Google Fonts**（CSP 只允許自己的網域）。
- **daisyUI 自訂 theme 必須定義 `--border`、`--depth`、`--noise`、`--size-field`、`--size-selector`**：少了的話 `.btn` 會變成瀏覽器預設的 3px 粗黑框、元件尺寸也會跑掉，而且不會報錯（`test/assets/theme_test.rb` 檢查）。
- 頁面結構：每頁用 `content_for :header` 放 `PageHeaderComponent`（沒有全站導覽列），內容用 `page-container`（手機 20px、桌機 32px 邊距，最寬 1360px）。
- 版面規則：可點擊元素 ≥ 44×44（膠囊用 `min-h-11`）；手機篩選用橫向膠囊列 + 「更多篩選」抽屜；隱藏的 checkbox（`sr-only` 是絕對定位）的外層 label 要 `relative`，否則會跑出捲動區而撐寬整個頁面（手機會左右晃動）。
- iOS：`viewport-fit=cover` + `env(safe-area-inset-*)`；輸入框字級 ≥ 16px；提供 PWA manifest。
- 複製按鈕：同一個 Stimulus click handler 內先 `navigator.clipboard.writeText`，成功顯示「已複製」再 `window.location.href` 開連結；失敗不跳轉，改為反白文字供手動複製。
- **前端行為要在真實瀏覽器驗證**：請求測試看不到 Turbo / Stimulus 的行為（是否整頁重載、frame 更新、抽屜開關）。用 `script/screenshot.mjs` 同樣的 DevTools 協定，在頁面內執行腳本操作並檢查結果（2026-10 以此驗證過收藏、候選、篩選膠囊、抽屜、巢狀表單、店家連結的手機 / 桌機行為）。
- **操作行為用 `script/browser_eval.mjs`**：在真實瀏覽器執行一段腳本（點按鈕、等 frame 更新、讀剪貼簿、記錄頁面要求的導覽網址），印出 JSON 結果。headless Chrome 預設沒有焦點，腳本已開啟焦點模擬與剪貼簿授權，否則 `clipboard` 會被拒。
- **改畫面後要看實際截圖**：`node script/screenshot.mjs <網址> <輸出.png> 390 844 mobile`（會印出 scrollWidth / clientWidth，兩者不同就是橫向溢出）。測試抓不到版面問題（例如粗黑框、橫向溢出）。
- 設計稿尚未涵蓋、由我們依其視覺語言補上的：曾訂購圓點、「僅飲料」標籤、新增店家入口（首頁右上角「＋」）、更多篩選抽屜。設計稿有但目前不做的：地圖（M5）、「每日 06:00 更新」（M5）。設定齒輪（首頁右上角，連到 `/setting/edit`）已在 M2-d1 完成。

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
| M2 商家與訂單 | a 資料模型、b 店家 CRUD / 貼上菜單 / 列表篩選 / 收藏候選 / 設計稿樣式（以上已合併）、側欄（瀏覽歷史、收藏、已詢問、已訂購頁面，已合併）、d1 活動與收餐設定頁（已合併）；待做：c 候選名單頁（排序、備註）、d2 訂單詢問產生器（已合併）、f 兩家配對訂購（進行中）、e 詢問單確認訂購與補登紀錄的操作。不含地圖 | 進行中 |
| M3 人數與日期 | KKTIX Webhook、總預算、人數變動提示、Ruby Jam 日期倒數 | 未開始 |
| M4 AI | 菜單照片 / 網址解析、建議搭配。已決定：用 OpenAI 視覺模型（`OPENAI_API_KEY`）；上傳的圖片只在記憶體處理、辨識完不保留（不用 ActiveStorage）；辨識結果沿用「貼上菜單」的預覽 → 確認才寫入，價格一定要人確認；排在 M2-d2 之後 | 未開始 |
| M5 自動搜尋 | Google Places、網頁搜尋、Threads、Instagram、每日排程與地圖 | 未開始 |

## CI（GitHub Actions）

Job：scan_ruby（Brakeman 有警告即失敗 + bundler-audit）、scan_secrets（gitleaks）、scan_js（importmap audit）、lint（RuboCop）、test。系統測試 job 待 M2 有系統測試時再加。任一失敗不合併、不部署。main 分支保護：CI 通過才能合併；Dependabot 已開啟。
