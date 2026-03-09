OctoStripeGateway::Engine.routes.draw do
  resources :payments, only: [ :create, :show ] do
    member do
      patch :complete
      post :refund
    end
  end

  post "webhooks", to: "webhooks#create"
end
