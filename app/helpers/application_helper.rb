module ApplicationHelper
  # 列舉值轉中文：enum_text(merchant, :delivers_at_19) # => "待確認"
  # 文字定義在 config/locales/zh-TW.yml 的 enums.<model>.<attribute>.<value>
  def enum_text(record, attribute)
    value = record.public_send(attribute)
    return if value.blank?

    t("enums.#{record.model_name.i18n_key}.#{attribute}.#{value}")
  end

  # 金額顯示。「未知」是 nil，不是 0：預設顯示「待確認」，絕不顯示成 NT$0。
  def format_money(amount, unknown: t("common.unknown_amount"))
    return unknown if amount.nil?

    "NT$#{number_with_delimiter(amount)}"
  end

  # 日期顯示，沒有日期時回傳 fallback
  def format_date(date, fallback: t("common.not_filled"))
    date ? l(date.to_date, format: :long) : fallback
  end

  # 下拉選單的選項：[[中文, 值], ...]，文字取自 zh-TW.yml 的 enums
  def enum_options(model, attribute)
    model.public_send(attribute.to_s.pluralize).keys.map do |value|
      [ t("enums.#{model.model_name.i18n_key}.#{attribute}.#{value}"), value ]
    end
  end
end
