# frozen_string_literal: true

require "stripe"

module OctoStripeGateway
  class StripeClient
    def create_payment_intent(amount, currency = nil)
      Stripe::PaymentIntent.create(
        { amount: amount, currency: currency || OctoStripeGateway.currency },
        { api_key: api_key }
      )
    end

    def find_payment_intent(payment_intent_id)
      Stripe::PaymentIntent.retrieve(payment_intent_id, { api_key: api_key })
    end

    def refund_payment_intent(payment_intent_id)
      Stripe::Refund.create({ payment_intent: payment_intent_id }, { api_key: api_key })
    end

    private

    def api_key
      OctoStripeGateway.stripe_api_key
    end
  end
end
