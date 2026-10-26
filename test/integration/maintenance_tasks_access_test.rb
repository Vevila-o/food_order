require "test_helper"

# Maintenance Tasks 預設不受 Basic Auth 保護；這裡確認我們把它接到 ApplicationController 了。
class MaintenanceTasksAccessTest < ActionDispatch::IntegrationTest
  test "沒帶帳密回 401" do
    with_env(AUTH_ENV) do
      get "/tasks"
      assert_response :unauthorized
    end
  end

  test "帳密錯誤回 401" do
    with_env(AUTH_ENV) do
      get "/tasks", headers: basic_auth_headers("jam", "wrong")
      assert_response :unauthorized
    end
  end

  test "帳密正確可看到任務清單" do
    with_env(AUTH_ENV) do
      get "/tasks", headers: basic_auth_headers("jam", "s3cret-pass")
      assert_response :success
      assert_includes response.body, "Maintenance::SeedSampleDataTask"
    end
  end

  test "正式環境缺少帳密時一樣回 401" do
    with_env("ACCESS_USER" => nil, "ACCESS_PASSWORD" => nil) do
      with_rails_env("production") do
        get "/tasks"
        assert_response :unauthorized
      end
    end
  end
end
