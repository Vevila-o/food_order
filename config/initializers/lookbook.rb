# Lookbook（元件預覽）只在開發環境使用，網址 /lookbook。
# 它的介面需要 inline script / style，會被全站嚴格的 CSP 擋掉，所以只在開發環境對 Lookbook 自己的 controller 關閉 CSP。
# 正式環境沒有安裝 Lookbook（Gemfile 的 development 群組），這裡不會執行。
if Rails.env.development?
  Rails.application.config.to_prepare do
    Lookbook::ApplicationController.content_security_policy(false)
  end
end
