# frozen_string_literal: true

require "stripe"

module OctoStripeGateway
  class StripeClient
    def create_payment_intent(amount, currency = nil, idempotency_key: nil)
      Stripe::PaymentIntent.create(
        { amount: amount, currency: currency || OctoStripeGateway.currency },
        { api_key: api_key, idempotency_key: idempotency_key }.compact
      )
    rescue Stripe::StripeError => e
      Rails.logger.error("[OctoStripeGateway] create_payment_intent failed: #{e.message}")
      raise
    end

    def find_payment_intent(payment_intent_id)
      Stripe::PaymentIntent.retrieve(payment_intent_id, { api_key: api_key })
    rescue Stripe::StripeError => e
      Rails.logger.error("[OctoStripeGateway] find_payment_intent failed for #{payment_intent_id}: #{e.message}")
      raise
    end

    def refund_payment_intent(payment_intent_id, idempotency_key: nil)
      Stripe::Refund.create(
        { payment_intent: payment_intent_id },
        { api_key: api_key, idempotency_key: idempotency_key }.compact
      )
    rescue Stripe::StripeError => e
      Rails.logger.error("[OctoStripeGateway] refund_payment_intent failed for #{payment_intent_id}: #{e.message}")
      raise
    end

    private

    def api_key
      OctoStripeGateway.stripe_api_key
    end
  end
end
