# 全站導覽列。連結由這裡集中管理，之後各里程碑在 links 加項目即可。
class HeaderComponent < ViewComponent::Base
  def links
    [
      [ "新增店家", helpers.new_merchant_path ]
    ]
  end
end
