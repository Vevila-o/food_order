# Ruby Jam 訂餐助手

每月為 Ruby Jam 找餐廳、算人數、產生詢問訊息，把數小時的工作縮短到 15 分鐘內。

系統負責整理候選店家與產生訊息；**聯絡店家的動作仍由使用者本人複製訊息後送出**（不自動傳訊、不線上付款、無多使用者帳號）。

- Ruby 4.0.6、Rails 8.1.4、PostgreSQL（正式為 Neon）
- Hotwire（Turbo + Stimulus）、importmap、Tailwind CSS + daisyUI、Solid Queue
- 測試：Minitest + WebMock + VCR

完整規格見規格書；協作規則與架構摘要見 [CLAUDE.md](CLAUDE.md)。

## 本機啟動

需求：rbenv（Ruby 4.0.6）、PostgreSQL。

```bash
bin/setup            # 安裝 gem、建立資料庫
cp .env.example .env # 視需要填入帳密（本機留空則不驗證）
bin/dev              # 啟動 web 與 Tailwind watcher
```

開啟 http://localhost:3000 。

## 環境變數

完整範本見 [.env.example](.env.example)。`.env` 已列入 `.gitignore`，金鑰絕不進 Git。

| 變數 | 用途 | 里程碑 |
| --- | --- | --- |
| `ACCESS_USER` / `ACCESS_PASSWORD` | 全站 HTTP Basic Auth（正式環境缺少時一律 401） | M1 |
| `DATABASE_URL` | Neon 連線字串，需含 `sslmode=require`（僅正式環境） | M1 |
| `SOLID_QUEUE_IN_PUMA` | 單機部署讓 Puma 內嵌 Solid Queue（Dockerfile 已設定） | M1 |
| `RAILS_MASTER_KEY` | Rails credentials 解密金鑰（不進 Git、不進 Docker image） | M1 |
| `KKTIX_WEBHOOK_SECRET` | KKTIX Webhook 驗證（`openssl rand -hex 32`） | M3 |
| `GITHUB_TOKEN` | 讀 Ruby Taiwan GitHub Project（fine-grained、唯讀） | M3 |
| `OPENAI_API_KEY` | AI 解析與建議搭配（專案專用 key，設每月上限） | M4 |
| `GOOGLE_PLACES_API_KEY` | 搜尋店家（限定 Places API 與伺服器 IP） | M5 |

存取保護細節見 [docs/basic-auth.md](docs/basic-auth.md)。

## 測試與檢查

```bash
bin/rails test                             # 測試
bin/rubocop                                # 風格檢查
bin/brakeman --no-pager                    # 資安掃描
bundle exec bundler-audit check --update   # gem 漏洞
bin/importmap audit                        # JS 套件漏洞
bin/ci                                     # 一次跑完以上全部
```

GitHub Actions 會在每次 push / PR 執行 Brakeman、bundler-audit、gitleaks、importmap audit、RuboCop 與測試；任一失敗就不合併、不部署。

## 部署

Rails 預設的 Dockerfile（正式映像排除 development / test 群組）：

```bash
docker build -t ruby-jam-lunch .
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY=<config/master.key 的值> \
  -e DATABASE_URL=<Neon 連線字串> \
  -e ACCESS_USER=<帳號> -e ACCESS_PASSWORD=<密碼> \
  ruby-jam-lunch
```

部署主機尚未決定（規格書確認項 #11）。

## 里程碑

| 階段 | 內容 | 狀態 |
| --- | --- | --- |
| M1 骨架 | Rails、Docker、GitHub Actions、存取保護、daisyUI theme | 完成 |
| M2 商家與訂單 | 手動新增店家、卡片與篩選、收藏 / 候選、詳情頁、訂單詢問產生器 | 未開始 |
| M3 人數與日期 | KKTIX Webhook、總預算、人數變動提示、Ruby Jam 日期倒數 | 未開始 |
| M4 AI | 菜單照片 / 網址解析、建議搭配 | 未開始 |
| M5 自動搜尋 | Google Places、網頁搜尋、Threads、Instagram、每日排程與地圖 | 未開始 |
