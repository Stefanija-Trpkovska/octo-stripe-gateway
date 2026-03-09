Rails.application.routes.draw do
  mount OctoStripeGateway::Engine => "/payments"
end
