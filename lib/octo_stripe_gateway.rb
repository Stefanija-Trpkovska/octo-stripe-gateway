# frozen_string_literal: true

require "octo_stripe_gateway/version"
require "octo_stripe_gateway/engine"
require "octo_stripe_gateway/stripe_client"

module OctoStripeGateway
  mattr_accessor :stripe_api_key
  @@stripe_api_key = ENV.fetch("STRIPE_API_KEY", "sk_test_default_key")

  mattr_accessor :stripe_publishable_key
  @@stripe_publishable_key = ENV.fetch("STRIPE_PUBLISHABLE_KEY", "pk_test_default_key")

  mattr_accessor :stripe_webhook_secret
  @@stripe_webhook_secret = ENV.fetch("STRIPE_WEBHOOK_SECRET", "whsec_test_default")

  mattr_accessor :currency
  @@currency = "usd"

  def self.setup
    yield self
  end
end
