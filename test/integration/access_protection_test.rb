require "test_helper"

class AccessProtectionTest < ActionDispatch::IntegrationTest
  test "已設定帳密但沒帶憑證時回 401" do
    with_env(AUTH_ENV) do
      get root_path
      assert_response :unauthorized
    end
  end

  test "密碼錯誤時回 401" do
    with_env(AUTH_ENV) do
      get root_path, headers: basic_auth_headers("jam", "wrong")
      assert_response :unauthorized
    end
  end

  test "帳密正確時可看到首頁" do
    with_env(AUTH_ENV) do
      get root_path, headers: basic_auth_headers("jam", "s3cret-pass")
      assert_response :success
    end
  end

  test "health check 不需要帳密" do
    with_env(AUTH_ENV) do
      get rails_health_check_path
      assert_response :success
    end
  end

  test "PWA manifest 不需要帳密" do
    with_env(AUTH_ENV) do
      get pwa_manifest_path(format: :json)
      assert_response :success
      assert_equal "Ruby Jam 訂餐助手", response.parsed_body["name"]
    end
  end

  test "本機未設定帳密時不要求驗證" do
    with_env("ACCESS_USER" => nil, "ACCESS_PASSWORD" => nil) do
      get root_path
      assert_response :success
    end
  end

  test "正式環境缺少帳密時全站回 401" do
    with_env("ACCESS_USER" => nil, "ACCESS_PASSWORD" => nil) do
      with_rails_env("production") do
        get root_path, headers: basic_auth_headers("", "")
        assert_response :unauthorized
      end
    end
  end
end
