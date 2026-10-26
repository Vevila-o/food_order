require "test_helper"

# daisyUI 自訂 theme 的必要變數。少了它們畫面不會報錯，但按鈕會出現 3px 粗黑框、元件尺寸跑掉
# （2026-10 發生過：theme 沒定義 --border / --size-field，直到看截圖才發現）。
class ThemeTest < ActiveSupport::TestCase
  CSS = Rails.root.join("app/assets/tailwind/application.css").read

  REQUIRED = %w[
    --color-base-100 --color-base-200 --color-base-300 --color-base-content
    --color-primary --color-primary-content --color-secondary --color-secondary-content
    --color-accent --color-accent-content --color-neutral --color-neutral-content
    --color-info --color-info-content --color-success --color-success-content
    --color-warning --color-warning-content --color-error --color-error-content
    --radius-selector --radius-field --radius-box
    --size-selector --size-field --border --depth --noise
  ].freeze

  test "自訂 theme 定義了 daisyUI 需要的全部變數" do
    missing = REQUIRED.reject { |name| CSS.match?(/^\s*#{Regexp.escape(name)}:\s*\S+;/) }

    assert_empty missing, "theme 缺少：#{missing.join(', ')}"
  end

  test "補充色票用 @theme 宣告（text-muted、bg-soft 等 class 才會產生）" do
    %w[--color-muted --color-soft --color-accent-soft --color-warning-soft --font-sans].each do |name|
      assert_match(/@theme\s*\{[^}]*#{Regexp.escape(name)}:/m, CSS, "@theme 缺少 #{name}")
    end
  end

  test "字型用系統字型，不載入外部字型（CSP 只允許自己的網域）" do
    assert_match(/--font-sans:[^;]*PingFang TC/, CSS)
    assert_no_match(/fonts\.googleapis\.com|@import url\(/, CSS)
  end
end
