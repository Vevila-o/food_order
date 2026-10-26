ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require "vcr"

# 外部 API 一律走 WebMock + VCR：測試不打真實 API，沒有錄製檔的請求直接失敗。
WebMock.disable_net_connect!(allow_localhost: true)

VCR.configure do |config|
  config.cassette_library_dir = "test/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.default_cassette_options = { record: :none }
  config.ignore_localhost = true
  # 錄製檔不得含金鑰
  config.filter_sensitive_data("<OPENAI_API_KEY>") { ENV["OPENAI_API_KEY"] }
  config.filter_sensitive_data("<GOOGLE_PLACES_API_KEY>") { ENV["GOOGLE_PLACES_API_KEY"] }
  config.filter_sensitive_data("<GITHUB_TOKEN>") { ENV["GITHUB_TOKEN"] }
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # 暫時設定環境變數（值為 nil 代表移除），區塊結束後還原。
    def with_env(vars)
      original = vars.keys.index_with { |key| ENV[key] }
      vars.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
      yield
    ensure
      original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    end

    # 暫時切換 Rails.env，用來測試正式環境行為。
    def with_rails_env(name)
      original = Rails.env
      Rails.env = name
      yield
    ensure
      Rails.env = original
    end
  end
end

class ActionDispatch::IntegrationTest
  AUTH_ENV = { "ACCESS_USER" => "jam", "ACCESS_PASSWORD" => "s3cret-pass" }.freeze

  # HTTP Basic Auth header
  def basic_auth_headers(user, password)
    { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(user, password) }
  end
end
