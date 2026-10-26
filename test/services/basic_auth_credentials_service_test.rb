require "test_helper"

class BasicAuthCredentialsServiceTest < ActiveSupport::TestCase
  test "帳密正確時通過驗證" do
    with_env("ACCESS_USER" => "jam", "ACCESS_PASSWORD" => "s3cret-pass") do
      assert BasicAuthCredentialsService.valid?("jam", "s3cret-pass")
    end
  end

  test "帳號或密碼錯誤時不通過" do
    with_env("ACCESS_USER" => "jam", "ACCESS_PASSWORD" => "s3cret-pass") do
      assert_not BasicAuthCredentialsService.valid?("jam", "wrong")
      assert_not BasicAuthCredentialsService.valid?("other", "s3cret-pass")
      assert_not BasicAuthCredentialsService.valid?(nil, nil)
    end
  end

  test "未設定帳密時一律不通過" do
    with_env("ACCESS_USER" => nil, "ACCESS_PASSWORD" => nil) do
      assert_not BasicAuthCredentialsService.configured?
      assert_not BasicAuthCredentialsService.valid?("", "")
      assert_not BasicAuthCredentialsService.valid?(nil, nil)
    end
  end

  test "只設定其中一個變數視為未設定" do
    with_env("ACCESS_USER" => "jam", "ACCESS_PASSWORD" => nil) do
      assert_not BasicAuthCredentialsService.configured?
    end
  end

  test "開發與測試環境未設定帳密時不要求驗證" do
    with_env("ACCESS_USER" => nil, "ACCESS_PASSWORD" => nil) do
      assert_not BasicAuthCredentialsService.required?
    end
  end

  test "已設定帳密時要求驗證" do
    with_env("ACCESS_USER" => "jam", "ACCESS_PASSWORD" => "s3cret-pass") do
      assert BasicAuthCredentialsService.required?
    end
  end

  test "正式環境即使未設定帳密也要求驗證" do
    with_env("ACCESS_USER" => nil, "ACCESS_PASSWORD" => nil) do
      with_rails_env("production") do
        assert BasicAuthCredentialsService.required?
      end
    end
  end
end
