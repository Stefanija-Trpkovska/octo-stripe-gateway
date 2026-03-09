# frozen_string_literal: true

require "spec_helper"

RSpec.describe OctoStripeGateway::StripeClient do
  subject(:client) { described_class.new }

  before do
    OctoStripeGateway.stripe_api_key = "sk_test_fake"
  end

  describe "#create_payment_intent" do
    it "creates a Stripe PaymentIntent with amount and currency" do
      intent = stripe_payment_intent
      allow(Stripe::PaymentIntent).to receive(:create).and_return(intent)

      result = client.create_payment_intent(2000, "usd")

      expect(Stripe::PaymentIntent).to have_received(:create).with(amount: 2000, currency: "usd")
      expect(result.id).to eq("pi_test_123")
      expect(result.client_secret).to eq("pi_test_123_secret_abc")
      expect(result.status).to eq("requires_payment_method")
    end

    it "uses default currency when none provided" do
      OctoStripeGateway.currency = "eur"
      allow(Stripe::PaymentIntent).to receive(:create).and_return(stripe_payment_intent)

      client.create_payment_intent(1000)

      expect(Stripe::PaymentIntent).to have_received(:create).with(amount: 1000, currency: "eur")
    end
  end

  describe "#find_payment_intent" do
    it "retrieves a PaymentIntent by ID" do
      intent = stripe_payment_intent(status: "succeeded")
      allow(Stripe::PaymentIntent).to receive(:retrieve).and_return(intent)

      result = client.find_payment_intent("pi_test_123")

      expect(Stripe::PaymentIntent).to have_received(:retrieve).with("pi_test_123")
      expect(result.status).to eq("succeeded")
    end
  end
end
