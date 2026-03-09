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
      render json: { error: "Invalid signature" }, status: :bad_request
    end

    private

    def handle_event(event)
      return unless event.type.start_with?("payment_intent.")

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
  end
end
