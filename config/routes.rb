Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    get :health, to: "health#show"

    post "auth/apple", to: "auth#apple"

    get "users/me", to: "users#me"
    get "users/me/feedback", to: "feedback#index"
    post "feedback", to: "app_feedbacks#create"

    resources :bundles, only: %i[create show update destroy] do
      collection do
        get :mine
      end
      member do
        post :share
      end
    end

    resources :bundle_shares, only: %i[index] do
      member do
        post :accept
      end
    end

    resources :review_sessions, only: %i[create show] do
      collection do
        get :pending
      end
      member do
        post :join
        patch :end, action: :end_session
        patch :state, action: :update_state
        get :marks
        post :marks, action: :create_mark
      end
    end

    delete "session_marks/:id", to: "session_marks#destroy"
  end
end
