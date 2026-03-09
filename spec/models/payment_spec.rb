# frozen_string_literal: true

require "spec_helper"

RSpec.describe OctoStripeGateway::Payment, type: :model do
  let(:payment) { described_class.create!(amount: 2000, currency: "usd") }
  let(:stripe_client) { instance_double(OctoStripeGateway::StripeClient) }

  before do
    allow(OctoStripeGateway::StripeClient).to receive(:new).and_return(stripe_client)
  end

  it "is pending by default" do
    expect(payment).to be_pending
  end

  it "validates amount is positive" do
    invalid = described_class.new(amount: 0, currency: "usd")
    expect(invalid).not_to be_valid
  end

  describe "#create_payment_intent" do
    it "creates a Stripe PaymentIntent and stores the response" do
      intent = stripe_payment_intent
      allow(stripe_client).to receive(:create_payment_intent).and_return(intent)

      payment.create_payment_intent

      payment.reload
      expect(payment.stripe_payment_intent_id).to eq("pi_test_123")
      expect(payment.stripe_client_secret).to eq("pi_test_123_secret_abc")
    end

    it "does nothing if payment intent already exists" do
      payment.update!(stripe_payment_intent_id: "pi_existing")
      allow(stripe_client).to receive(:create_payment_intent)

      payment.create_payment_intent

      expect(stripe_client).not_to have_received(:create_payment_intent)
    end
  end

  describe "#confirm_payment" do
    before do
      payment.update!(stripe_payment_intent_id: "pi_test_123")
    end

    it "marks payment as paid when Stripe returns succeeded" do
      allow(stripe_client).to receive(:find_payment_intent)
        .and_return(stripe_payment_intent(status: "succeeded"))

      payment.confirm_payment

      payment.reload
      expect(payment).to be_paid
      expect(payment.paid_at).to be_present
    end

    it "does nothing if already paid" do
      payment.update!(status: :paid, paid_at: Time.current)
      allow(stripe_client).to receive(:find_payment_intent)

      payment.confirm_payment

      expect(stripe_client).not_to have_received(:find_payment_intent)
    end

    it "stays pending when Stripe status is requires_payment_method" do
      allow(stripe_client).to receive(:find_payment_intent)
        .and_return(stripe_payment_intent(status: "requires_payment_method"))

      payment.confirm_payment

      expect(payment.reload).to be_pending
    end

    it "stays pending when Stripe status is requires_action" do
      allow(stripe_client).to receive(:find_payment_intent)
        .and_return(stripe_payment_intent(status: "requires_action"))

      payment.confirm_payment

      expect(payment.reload).to be_pending
    end
  end
end
