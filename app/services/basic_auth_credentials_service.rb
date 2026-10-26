# 全站 HTTP Basic Auth 的帳密比對。
# 帳密只來自環境變數 ACCESS_USER / ACCESS_PASSWORD，不寫進程式碼。
# 細節見 docs/basic-auth.md。
class BasicAuthCredentialsService
  class << self
    # 正式環境一律要驗證；開發 / 測試只有設了環境變數才驗證，方便本機開發。
    def required?
      Rails.env.production? || configured?
    end

    def configured?
      expected_user.present? && expected_password.present?
    end

    # 未設定帳密時一律回 false（正式環境缺變數就是全站 401，而不是全開）。
    def valid?(user, password)
      return false unless configured?

      # 先轉成 SHA256 再比對：長度固定，secure_compare 不會洩漏帳密長度。
      user_ok = secure_compare(user, expected_user)
      password_ok = secure_compare(password, expected_password)
      user_ok & password_ok
    end

    private

    def expected_user = ENV["ACCESS_USER"].to_s

    def expected_password = ENV["ACCESS_PASSWORD"].to_s

    def secure_compare(given, expected)
      ActiveSupport::SecurityUtils.secure_compare(
        Digest::SHA256.hexdigest(given.to_s),
        Digest::SHA256.hexdigest(expected)
      )
    end
  end
end
