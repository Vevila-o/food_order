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
  end

  root "merchants#index"
end
