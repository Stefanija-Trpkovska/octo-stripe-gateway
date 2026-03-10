# frozen_string_literal: true

require "octo_stripe_gateway/version"
require "octo_stripe_gateway/engine"
require "octo_stripe_gateway/stripe_client"

module OctoStripeGateway
  mattr_accessor :stripe_api_key
  @@stripe_api_key = ENV.fetch("STRIPE_API_KEY", "sk_test_51T8o7L4VWrif3G06pwoVQYcAJwD9JZbDkHSFPfLI0BWwagG3HOQQhiH3aHlnNeUZq7t3K4AL788Ue546FkkMZ50100GqgzqMmR")

  mattr_accessor :stripe_publishable_key
  @@stripe_publishable_key = ENV.fetch("STRIPE_PUBLISHABLE_KEY", "pk_test_51T8o7L4VWrif3G06jbknTqCBp0HLgjnBTClsdK4QZSi0swM51SQGHTAD1a1WDDoxtXA4vGMIZL8gVrUsd4ILGPH400sJMRTlRy")

  mattr_accessor :stripe_webhook_secret
  @@stripe_webhook_secret = ENV["STRIPE_WEBHOOK_SECRET"]

  mattr_accessor :currency
  @@currency = "usd"

  mattr_accessor :api_gateway_key
  @@api_gateway_key = ENV["OSG_API_GATEWAY_KEY"]

  mattr_accessor :authenticate
  @@authenticate = nil

  def self.setup
    yield self
  end
end
