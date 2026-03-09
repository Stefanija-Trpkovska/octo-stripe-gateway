# frozen_string_literal: true

require "octo_stripe_gateway/version"
require "octo_stripe_gateway/engine"
require "octo_stripe_gateway/stripe_client"

module OctoStripeGateway
  mattr_accessor :stripe_api_key
  @@stripe_api_key = ENV["STRIPE_API_KEY"]

  mattr_accessor :stripe_publishable_key
  @@stripe_publishable_key = ENV["STRIPE_PUBLISHABLE_KEY"]

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
