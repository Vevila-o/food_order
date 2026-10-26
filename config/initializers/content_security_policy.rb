# 內容安全政策（CSP）：只允許自己的網域與 OpenStreetMap 圖磚（M2 的 Leaflet 地圖使用）。
# 參考：https://guides.rubyonrails.org/security.html#content-security-policy-header
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :data, "https://*.tile.openstreetmap.org"
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self
    policy.connect_src :self
    policy.frame_ancestors :none
    policy.base_uri    :self
    policy.form_action :self
  end

  # importmap 的 inline script 需要 nonce
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
  config.content_security_policy_nonce_auto = true
end
