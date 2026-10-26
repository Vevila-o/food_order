require "test_helper"

module Merchants
  # 候選名單：加入 / 移除（既有）、排序、備註
  class ShortlistsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @a = create(:merchant, name: "甲", shortlisted: true, shortlist_position: 1)
      @b = create(:merchant, name: "乙", shortlisted: true, shortlist_position: 2)
      @c = create(:merchant, name: "丙", shortlisted: true, shortlist_position: 3)
    end

    def order = Merchant.shortlisted.map(&:name)

    test "往前一位：順序改變並導回候選名單頁（303）" do
      patch move_merchant_shortlist_path(@b, direction: "up")

      assert_redirected_to shortlist_path
      assert_response :see_other
      assert_equal %w[乙 甲 丙], order
    end

    test "往後一位" do
      patch move_merchant_shortlist_path(@a, direction: "down")

      assert_equal %w[乙 甲 丙], order
    end

    test "最前再往前、最後再往後：不動也不報錯（冪等）" do
      patch move_merchant_shortlist_path(@a, direction: "up")
      patch move_merchant_shortlist_path(@c, direction: "down")

      assert_response :see_other
      assert_equal %w[甲 乙 丙], order
    end

    test "不認得的方向、缺少方向、方向是陣列：不動，不報錯" do
      patch move_merchant_shortlist_path(@b, direction: "sideways")
      patch move_merchant_shortlist_path(@b)
      patch move_merchant_shortlist_path(@b), params: { direction: [ "up" ] }

      assert_response :see_other
      assert_equal %w[甲 乙 丙], order
    end

    test "不在候選的店家按排序：不動" do
      outsider = create(:merchant)

      patch move_merchant_shortlist_path(outsider, direction: "up")

      assert_equal %w[甲 乙 丙], order
      assert_not outsider.reload.shortlisted?
    end

    test "排序不改店家的更新時間" do
      before = @b.reload.updated_at

      travel(1.hour) { patch move_merchant_shortlist_path(@b, direction: "up") }

      assert_equal before, @b.reload.updated_at
    end

    test "儲存備註：導回候選名單頁並顯示提示" do
      patch merchant_shortlist_path(@b), params: { shortlist_note: "上次太鹹" }

      assert_redirected_to shortlist_path
      assert_equal "上次太鹹", @b.reload.shortlist_note
      follow_redirect!
      assert_select ".alert", text: /已儲存「乙」的備註/
      assert_select "textarea", text: /上次太鹹/
    end

    test "清空備註存成 nil" do
      @b.update_shortlist_note!("舊的")

      patch merchant_shortlist_path(@b), params: { shortlist_note: "  " }

      assert_nil @b.reload.shortlist_note
    end

    test "備註超過上限：不儲存並提示" do
      patch merchant_shortlist_path(@b), params: { shortlist_note: "字" * (Merchant::SHORTLIST_NOTE_LIMIT + 1) }

      assert_nil @b.reload.shortlist_note
      assert_match(/最多 500 字/, flash[:alert])
    end

    test "備註內容會跳脫，不會當成 HTML" do
      @b.update_shortlist_note!("<script>alert(1)</script>")

      get shortlist_path

      assert_select "script", text: /alert\(1\)/, count: 0
      assert_select "textarea", text: "<script>alert(1)</script>"
    end

    test "備註參數是陣列：當作沒帶，不報錯" do
      patch merchant_shortlist_path(@b), params: { shortlist_note: [ "x" ] }

      assert_response :see_other
      assert_nil @b.reload.shortlist_note
    end

    test "不存在的店家回 404" do
      patch move_merchant_shortlist_path(merchant_id: 0, direction: "up")

      assert_response :not_found
    end

    test "需要 Basic Auth" do
      with_env(AUTH_ENV) do
        patch move_merchant_shortlist_path(@b, direction: "up")
        assert_response :unauthorized

        patch merchant_shortlist_path(@b), params: { shortlist_note: "x" }
        assert_response :unauthorized
      end
      assert_equal %w[甲 乙 丙], order
    end
  end
end
