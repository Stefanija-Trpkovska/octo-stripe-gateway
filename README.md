# OctoStripeGateway

Rails engine that provides a Stripe payment API for SPAs, following the OCTo specification.

## Installation

Add to your Gemfile:

```ruby
gem "octo_stripe_gateway"
```

Mount the engine in `config/routes.rb`:

```ruby
mount OctoStripeGateway::Engine => "/payments"
```

Run the migration:

```bash
bundle install
bin/rails octo_stripe_gateway:install:migrations
bin/rails db:migrate
```

## Configuration

Create an initializer `config/initializers/octo_stripe_gateway.rb`:

```ruby
OctoStripeGateway.setup do |config|
  config.stripe_api_key = ENV["STRIPE_API_KEY"]
  config.stripe_publishable_key = ENV["STRIPE_PUBLISHABLE_KEY"]
  config.currency = "usd"
end
```

Test environment keys are used by default.

## API Endpoints

### Create Payment

```
POST /payments/payments.json
Params: { amount: 2000, currency: "usd" }
```

Returns the Stripe `client_secret` for the SPA to confirm with Stripe.js.

### Get Payment

```
GET /payments/payments/:id.json
```

### Complete Payment

```
GET /payments/payments/:id/complete.json
```

Checks with Stripe if the payment succeeded and updates the record.

## Polymorphic Association

Attach payments to any model in your app:

```ruby
class Booking < ApplicationRecord
  has_many :payments,
    class_name: "OctoStripeGateway::Payment",
    as: :payable
end
```

## Overriding the Controller

Include the concern in your own controller:

```ruby
class MyPaymentsController < ApplicationController
  include OctoStripeGateway::PaymentsControllerConcern
end
```

## Running Tests

```bash
bundle install
RAILS_ENV=test bin/rails db:create db:migrate
bundle exec rspec
```

## License

MIT
