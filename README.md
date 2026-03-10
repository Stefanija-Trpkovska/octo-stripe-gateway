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

**Requirements:** Ruby >= 3.2, Rails >= 8.0, PostgreSQL (uses Postgres enums)

## Configuration

Create an initializer `config/initializers/octo_stripe_gateway.rb`:

```ruby
OctoStripeGateway.setup do |config|
  config.stripe_api_key         = ENV["STRIPE_API_KEY"]
  config.stripe_publishable_key = ENV["STRIPE_PUBLISHABLE_KEY"]
  config.stripe_webhook_secret  = ENV["STRIPE_WEBHOOK_SECRET"]
  config.currency               = "usd" # default currency
  config.api_gateway_key        = ENV["OSG_API_GATEWAY_KEY"] # API authentication
end
```

The gem ships with Stripe test environment keys by default, so it works out of the box for development. Override with your own keys via env vars or the setup block for production.

## Authentication

The engine supports two authentication methods:

### API Key (default)

Set `api_gateway_key` in the config. Clients must pass it as a Bearer token:

```
Authorization: Bearer your_api_key
```

### Custom Authentication

Provide a proc for full control over authentication:

```ruby
OctoStripeGateway.setup do |config|
  config.authenticate = ->(request) {
    request.headers["X-Api-Token"] == ENV["MY_CUSTOM_TOKEN"]
  }
end
```

Return a truthy value to allow the request, falsy to deny.

Webhook endpoints skip authentication — they are protected by Stripe signature verification.

## API Endpoints

All endpoints return camelCase JSON following the OCTo specification.

### Create Payment

```
POST /payments/payments
Params: { amount: 2000, currency: "usd" }
Headers: { Authorization: "Bearer your_api_key" }
```

Response:

```json
{
  "id": 1,
  "amount": 2000,
  "currency": "usd",
  "status": "PENDING",
  "gateway": "stripe",
  "stripePaymentIntentId": "pi_...",
  "stripeClientSecret": "pi_..._secret_...",
  "publishableKey": "pk_test_..."
}
```

The `stripeClientSecret` is only returned on create. Use it with Stripe.js to confirm the payment on the frontend.

### Get Payment

```
GET /payments/payments/:id
```

### Complete Payment

```
PATCH /payments/payments/:id/complete
```

Checks with Stripe if the payment succeeded and updates the record.

### Refund Payment

```
POST /payments/payments/:id/refund
```

Refunds a paid payment via the Stripe Refund API. Only paid payments can be refunded.

### Status Values

| Internal | OCTo Response |
|----------|---------------|
| pending  | PENDING       |
| paid     | CONFIRMED     |
| failed   | FAILED        |
| refunded | REFUNDED      |

## Webhooks

The engine exposes a webhook endpoint at:

```
POST /payments/webhooks
```

Configure this URL in the [Stripe Dashboard](https://dashboard.stripe.com/webhooks) and subscribe to:

- `payment_intent.succeeded`
- `payment_intent.payment_failed`
- `charge.refunded`

Set the webhook signing secret in your config:

```ruby
config.stripe_webhook_secret = ENV["STRIPE_WEBHOOK_SECRET"]
```

Webhooks update payment status automatically, including refunds made directly from the Stripe Dashboard.

## Polymorphic Association

Attach payments to any model in your app:

```ruby
class Booking < ApplicationRecord
  has_many :payments,
    class_name: "OctoStripeGateway::Payment",
    as: :payable
end
```

## Overriding Controllers

Include the concerns in your own controllers:

```ruby
class MyPaymentsController < ApplicationController
  include OctoStripeGateway::PaymentsControllerConcern
end

class MyWebhooksController < ApplicationController
  skip_before_action :authenticate_request
  include OctoStripeGateway::WebhooksControllerConcern
end
```

## Notes

- **Idempotency:** All Stripe create/refund calls use idempotency keys to prevent duplicate charges on retries.
- **Concurrency:** Refund and confirm operations use pessimistic locking (`SELECT ... FOR UPDATE`) to prevent race conditions.
- **Logging:** Stripe errors are logged with the `[OctoStripeGateway]` tag for easy filtering.
- **Security:** The `stripe_client_secret` is never stored in the database. It is returned once on payment creation for use with Stripe.js.
- **Thread Safety:** Stripe API keys are passed per-request, not set globally.

## Running Tests

```bash
bundle install
RAILS_ENV=test bin/rails db:create db:migrate
bundle exec rspec
```

## License

MIT
