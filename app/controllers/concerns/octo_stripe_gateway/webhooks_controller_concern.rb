# frozen_string_literal: true

module OctoStripeGateway
  module WebhooksControllerConcern
    extend ActiveSupport::Concern

    def create
      event = Stripe::Webhook.construct_event(
        request.raw_post,
        request.headers["Stripe-Signature"],
        OctoStripeGateway.stripe_webhook_secret
      )

      handle_event(event)
      head :ok
    rescue Stripe::SignatureVerificationError
      Rails.logger.error("[OctoStripeGateway] Webhook signature verification failed")
      render json: { error: "Invalid signature" }, status: :bad_request
    end

    private

    def handle_event(event)
      case event.type
      when "payment_intent.succeeded", "payment_intent.payment_failed"
        handle_payment_intent_event(event)
      when "charge.refunded"
        handle_charge_refunded_event(event)
      end
    end

    def handle_payment_intent_event(event)
      payment_intent = event.data.object
      payment = Payment.find_by(stripe_payment_intent_id: payment_intent.id)
      return unless payment

      case event.type
      when "payment_intent.succeeded"
        payment.update!(status: :paid, paid_at: Time.current) unless payment.paid?
      when "payment_intent.payment_failed"
        message = payment_intent.last_payment_error&.message || "Payment failed"
        payment.update!(status: :failed, error_message: message) unless payment.failed?
      end
    end

    def handle_charge_refunded_event(event)
      charge = event.data.object
      payment_intent_id = charge.payment_intent
      return unless payment_intent_id

      payment = Payment.find_by(stripe_payment_intent_id: payment_intent_id)
      return unless payment

      payment.update!(status: :refunded, refunded_at: Time.current) unless payment.refunded?
    end
  end
end
