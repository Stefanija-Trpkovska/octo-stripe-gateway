OctoStripeGateway::Engine.routes.draw do
  resources :payments, only: [:create, :show] do
    member do
      get :complete
    end
  end
end
