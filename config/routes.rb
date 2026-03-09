OctoStripeGateway::Engine.routes.draw do
  resources :payments, only: [:create, :show] do
    member do
      patch :complete
    end
  end
end
