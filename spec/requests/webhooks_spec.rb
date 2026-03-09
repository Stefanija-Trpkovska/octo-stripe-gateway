# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Webhooks API", type: :request do
  let(:payment) do
    OctoStripeGateway::Payment.create!(
      amount: 2000,
      currency: "usd",
      stripe_payment_intent_id: "pi_webhook_123"
    )
  end

  def post_webhook(event)
    allow(Stripe::Webhook).to receive(:construct_event).and_return(event)

    post "/payments/webhooks",
      params: "{}",
      headers: { "Stripe-Signature" => "t=123,v1=abc" }
  end

  describe "POST /webhooks" do
    it "marks payment as paid on payment_intent.succeeded" do
      payment
      event = stripe_webhook_event(
        type: "payment_intent.succeeded",
        payment_intent_id: "pi_webhook_123"
      )

      post_webhook(event)

      expect(response).to have_http_status(:ok)
      expect(payment.reload).to be_paid
      expect(payment.paid_at).to be_present
    end

    it "marks payment as failed on payment_intent.payment_failed" do
      payment
      event = stripe_webhook_event(
        type: "payment_intent.payment_failed",
        payment_intent_id: "pi_webhook_123",
        error_message: "Your card was declined."
      )

      post_webhook(event)

      expect(response).to have_http_status(:ok)
      expect(payment.reload).to be_failed
      expect(payment.error_message).to eq("Your card was declined.")
    end

    it "returns 400 for invalid signature" do
      allow(Stripe::Webhook).to receive(:construct_event)
        .and_raise(Stripe::SignatureVerificationError.new("Invalid", "sig"))

      post "/payments/webhooks",
        params: "{}",
        headers: { "Stripe-Signature" => "invalid" }

      expect(response).to have_http_status(:bad_request)
    end

    it "ignores events for unknown payment intents" do
      event = stripe_webhook_event(
        type: "payment_intent.succeeded",
        payment_intent_id: "pi_unknown"
      )

      post_webhook(event)

      expect(response).to have_http_status(:ok)
    end

    it "does not update an already paid payment" do
      payment.update!(status: :paid, paid_at: 1.hour.ago)
      original_paid_at = payment.paid_at

      event = stripe_webhook_event(
        type: "payment_intent.succeeded",
        payment_intent_id: "pi_webhook_123"
      )

      post_webhook(event)

      expect(payment.reload.paid_at).to eq(original_paid_at)
    end
  end
end
