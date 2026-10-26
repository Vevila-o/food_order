# 這些參數與 header 的值不會出現在 log。
# 包含 KKTIX Webhook 的個資欄位（姓名、email、電話）與驗證 token（見規格書 7.5）。
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  :api_key, :authorization, :x_rubyjam_webhook_token,
  :name, :phone, :mobile, :tel
]
