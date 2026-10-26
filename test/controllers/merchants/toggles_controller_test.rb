require "test_helper"

module Merchants
  class TogglesControllerTest < ActionDispatch::IntegrationTest
    setup { @merchant = create(:merchant, name: "阿嬤便當") }

    def turbo_headers = { "Accept" => "text/vnd.turbo-stream.html" }

    # --- 收藏 ---

    test "收藏：Turbo Stream 只替換這顆按鈕，已按下狀態與 DELETE 表單" do
      post merchant_favorite_path(@merchant), headers: turbo_headers

      assert_response :success
      assert_equal "text/vnd.turbo-stream.html", response.media_type
      assert @merchant.reload.favorited
      assert_select "turbo-stream[action=replace][target=favorite_merchant_#{@merchant.id}]"
      assert_select "template button[aria-label=收藏][aria-pressed=true]"
      assert_select "template input[name=_method][value=delete]"
    end

    test "取消收藏" do
      @merchant.favorite!

      delete merchant_favorite_path(@merchant), headers: turbo_headers

      assert_not @merchant.reload.favorited
      assert_select "template button[aria-label=收藏][aria-pressed=false]"
    end

    test "沒有 JavaScript 時退回 redirect（回到原頁）" do
      post merchant_favorite_path(@merchant), headers: { "Referer" => merchants_url }

      assert_redirected_to merchants_url
      assert @merchant.reload.favorited
    end

    test "沒有 Referer 時回店家頁" do
      post merchant_favorite_path(@merchant)

      assert_redirected_to merchant_path(@merchant)
    end

    test "重複收藏結果一致（冪等）" do
      2.times { post merchant_favorite_path(@merchant), headers: turbo_headers }

      assert @merchant.reload.favorited
      assert_response :success
    end

    # --- 下次候選 ---

    test "加入候選：排在最後，按鈕變已按下" do
      create(:merchant).add_to_shortlist!

      post merchant_shortlist_path(@merchant), headers: turbo_headers

      assert_response :success
      assert @merchant.reload.shortlisted
      assert_equal 2, @merchant.shortlist_position
      assert_select "turbo-stream[target=shortlist_merchant_#{@merchant.id}]"
      assert_select "template button[aria-label=下次候選][aria-pressed=true]"
    end

    test "移出候選" do
      @merchant.add_to_shortlist!

      delete merchant_shortlist_path(@merchant), headers: turbo_headers

      assert_not @merchant.reload.shortlisted
      assert_nil @merchant.shortlist_position
      assert_select "template button[aria-label=下次候選][aria-pressed=false]"
    end

    test "收藏與候選互不影響" do
      post merchant_shortlist_path(@merchant), headers: turbo_headers

      assert_not @merchant.reload.favorited
    end

    # --- 共通 ---

    test "切換不會改變店家的更新時間" do
      @merchant.update_column(:updated_at, 3.days.ago)
      before = @merchant.reload.updated_at

      post merchant_favorite_path(@merchant), headers: turbo_headers

      assert_equal before, @merchant.reload.updated_at
    end

    test "找不到店家回 404" do
      post merchant_favorite_path(merchant_id: 0), headers: turbo_headers

      assert_response :not_found
    end

    test "已設定帳密時需要登入，沒登入不會變更" do
      with_env(AUTH_ENV) do
        post merchant_favorite_path(@merchant), headers: turbo_headers
        assert_response :unauthorized
        post merchant_shortlist_path(@merchant), headers: turbo_headers
        assert_response :unauthorized
      end

      assert_not @merchant.reload.favorited
      assert_not @merchant.shortlisted
    end

    test "首頁與店家頁都有切換按鈕，狀態來自資料" do
      @merchant.favorite!

      get merchants_path
      assert_select "article button[aria-label=收藏][aria-pressed=true]"
      assert_select "article button[aria-label=下次候選][aria-pressed=false]"

      get merchant_path(@merchant)
      assert_select "header button[aria-label=收藏][aria-pressed=true]"
      assert_select "header button[aria-label=下次候選][aria-pressed=false]"
    end

    test "切換後「只看收藏」篩選立刻反映" do
      post merchant_favorite_path(@merchant), headers: turbo_headers

      get merchants_path, params: { filter: { favorited: "1" } }

      assert_select "article h2 a", text: "阿嬤便當"
    end
  end
end
