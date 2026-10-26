require "test_helper"

# Lookbook 的預覽檔壞掉不會有人發現，直到有人打開 /lookbook；這個測試讓 CI 抓到。
class PreviewsTest < ViewComponent::TestCase
  test "所有元件預覽都能正常渲染" do
    previews = ViewComponent::Preview.all
    assert_operator previews.size, :>=, 8, "找不到預覽檔，預覽路徑設定可能壞了"

    previews.each do |preview|
      preview.examples.each do |example|
        begin
          render_preview(example, from: preview)
        rescue StandardError => e
          flunk "#{preview.name}##{example} 渲染失敗：#{e.class}: #{e.message}"
        end
      end
    end
  end

  test "每個元件都有預覽" do
    components = Dir[Rails.root.join("app/components/*_component.rb")].map { |path| File.basename(path, ".rb").camelize }
    previewed = ViewComponent::Preview.all.map { |preview| preview.name.delete_suffix("Preview") }

    assert_empty components - previewed, "這些元件還沒有 Lookbook 預覽"
  end

  test "預覽真的有把內容傳進元件（避免大括號綁錯方法，內容變成空的）" do
    render_preview(:all_types, from: AlertComponentPreview)

    assert_text "已儲存店家資料"
    assert_selector ".alert", count: 3
  end
end
