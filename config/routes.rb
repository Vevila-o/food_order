Rails.application.routes.draw do
  mount MaintenanceTasks::Engine, at: "/tasks"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA：manifest 與 service worker 由 app/views/pwa/* 動態渲染
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # 元件預覽（只有開發環境才安裝 Lookbook）
  mount Lookbook::Engine, at: "/lookbook" if Rails.env.development?

  resources :merchants do
    # 確認菜單仍有效：該店所有菜單項目的日期改為今天
    post :verify_menu, on: :member

    # 收藏與下次候選：POST 加入、DELETE 移除（重複操作結果一致）
    resource :favorite, only: %i[create destroy], module: :merchants
    resource :shortlist, only: %i[create destroy], module: :merchants

    # 貼上菜單：new（輸入）→ preview（預覽）→ create（確認寫入）
    resource :menu_import, only: %i[new create] do
      post :preview
    end
  end

  # 活動（日期、手動修正人數）與收餐資訊設定
  resources :events, only: %i[new create edit update]
  resource :setting, only: %i[edit update]

  # 側欄：瀏覽歷史、收藏、已詢問、已訂購
  get "history", to: "browsing_histories#index", as: :history
  get "favorites", to: "favorite_merchants#index", as: :favorites
  resources :inquiries, only: :index
  get "orders", to: "orders#index", as: :orders

  root "merchants#index"
end
