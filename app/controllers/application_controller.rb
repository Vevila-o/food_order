class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # 沒有註冊、單一角色：全站以 HTTP Basic Auth 保護，避免網址外流後被人觸發付費 API 或看到報名人數。
  # 例外：/up（Rails::HealthController）與 KKTIX Webhook（M3，自行驗證 header）不繼承此類別。
  before_action :require_access!

  private

  def require_access!
    return unless BasicAuthCredentialsService.required?

    authenticate_or_request_with_http_basic("Ruby Jam 訂餐助手") do |user, password|
      BasicAuthCredentialsService.valid?(user, password)
    end
  end
end
