class ToggleButtonComponentPreview < ViewComponent::Preview
  # 收藏（星號）：未收藏 → 已收藏
  def favorite
    render_pair(:favorite)
  end

  # 下次候選（書籤）：未加入 → 已加入
  def shortlist
    render_pair(:shortlist)
  end

  private

  def render_pair(kind)
    off = PreviewMerchants.build
    on = PreviewMerchants.build(favorited: true, shortlisted: true)
    render_with_template(template: "toggle_button_component_preview/pair", locals: { off: off, on: on, kind: kind })
  end
end
