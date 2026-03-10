# OctoStripeGateway

Rails engine that provides a Stripe payment API for SPAs, following the OCTo specification.

## Installation

Add to your Gemfile:

```ruby
gem "octo_stripe_gateway"
```

Mount the engine in `config/routes.rb`:

```ruby
mount OctoStripeGateway::Engine => "/bookings"
```

You can choose any mount path. The engine's internal routes (`/payments`, `/webhooks`) are appended to it, so the full paths become `/bookings/payments`, `/bookings/webhooks`, etc.

Run the migration:

```bash
bundle install
bin/rails db:migrate
```

The engine automatically adds its migrations to your app at boot, no extra install step needed. If you prefer to copy the migrations into your app instead (e.g. to customize them), you can run:

```bash
bin/rails octo_stripe_gateway:install:migrations
```

**Note:** Do not do both. The engine already loads its migrations automatically, so running `install:migrations` on top of that will cause a `DuplicateMigrationNameError`. Use one approach or the other.

**Requirements:** Ruby >= 3.2, Rails >= 8.0, PostgreSQL (uses Postgres enums)

## Configuration

Create an initializer `config/initializers/octo_stripe_gateway.rb`:

```ruby
OctoStripeGateway.setup do |config|
  config.stripe_api_key         = ENV["STRIPE_API_KEY"]         if ENV["STRIPE_API_KEY"]
  config.stripe_publishable_key = ENV["STRIPE_PUBLISHABLE_KEY"] if ENV["STRIPE_PUBLISHABLE_KEY"]
  config.stripe_webhook_secret  = ENV["STRIPE_WEBHOOK_SECRET"]  if ENV["STRIPE_WEBHOOK_SECRET"]
  config.currency               = "usd" # default currency
  config.api_gateway_key        = ENV["OSG_API_GATEWAY_KEY"]    if ENV["OSG_API_GATEWAY_KEY"]
end
```

The gem ships with Stripe test keys by default, so it works out of the box for development. The initializer above only overrides when the ENV var is actually set, otherwise the gem's built-in test keys are preserved. Set your own keys via env vars or directly in the setup block for production.

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

Webhook endpoints skip authentication, they are protected by Stripe signature verification.

## API Endpoints

All endpoints return camelCase JSON following the OCTo specification. The paths below assume the engine is mounted at `/bookings`.

### Create Payment

```
POST /bookings/payments
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
GET /bookings/payments/:id
```

### Complete Payment

```
PATCH /bookings/payments/:id/complete
```

Checks with Stripe if the payment succeeded and updates the record.

### Refund Payment

```
POST /bookings/payments/:id/refund
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
POST /bookings/webhooks
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
