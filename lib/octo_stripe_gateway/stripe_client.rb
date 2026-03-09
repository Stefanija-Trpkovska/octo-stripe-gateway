# frozen_string_literal: true

require "stripe"

module OctoStripeGateway
  class StripeClient
    def initialize
      Stripe.api_key = OctoStripeGateway.stripe_api_key
    end

    def create_payment_intent(amount, currency = nil)
      Stripe::PaymentIntent.create(
        amount: amount,
        currency: currency || OctoStripeGateway.currency
      )
    end

    def find_payment_intent(payment_intent_id)
      Stripe::PaymentIntent.retrieve(payment_intent_id)
    end
  end
end
