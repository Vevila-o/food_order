require "ipaddr"

# 使用者輸入的網址只允許 https，並擋掉 localhost 與內網 IP（規格書 7.3，防 SSRF 與 javascript: 之類的連結）。
# 這裡只檢查字面上的網址；實際抓取網頁（M4）時還要另外檢查 DNS 解析後的 IP。
class HttpsUrlValidator < ActiveModel::EachValidator
  BLOCKED_SUFFIXES = %w[.local .internal .localhost].freeze

  def validate_each(record, attribute, value)
    return if value.blank?

    record.errors.add(attribute, options[:message] || "必須是公開的 https 網址") unless public_https?(value)
  end

  private

  def public_https?(value)
    uri = URI.parse(value.to_s)
    return false unless uri.is_a?(URI::HTTPS) && uri.host.present?

    host = uri.host.downcase
    return false if host == "localhost" || BLOCKED_SUFFIXES.any? { |suffix| host.end_with?(suffix) }

    !blocked_ip?(host)
  rescue URI::InvalidURIError
    false
  end

  def blocked_ip?(host)
    ip = IPAddr.new(host.delete_prefix("[").delete_suffix("]"))
    ip.private? || ip.loopback? || ip.link_local? || ip.to_s == "0.0.0.0" || ip.to_s == "::"
  rescue IPAddr::InvalidAddressError
    false # 不是 IP 字面值，視為一般網域
  end
end
