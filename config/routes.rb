Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }
  resource :profile, only: [:show, :edit, :update]

  resources :pericias do
    resources :documento_bases, only: [:show, :edit, :update] do
      member do
        post :marcar_revisado
        get  :export_pdf
      end
    end
    resources :pericia_documents, only: [:create, :destroy]
    resources :laudo_sections, only: [:update]
    resources :quesito_respostas, only: [:update]
    member do
      get   :review
      get   :review_docs_base
      post  :extract_processo
      get   :review_transcricao
      patch :update_transcricao
      post  :generate_laudo
      post  :confirmar_fase1
      post  :generate_pdf
    end
  end

  root to: "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
