# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Payments API", type: :request do
  let(:stripe_client) { instance_double(OctoStripeGateway::StripeClient) }

  before do
    allow(OctoStripeGateway::StripeClient).to receive(:new).and_return(stripe_client)
  end

  describe "POST /payments" do
    before do
      allow(stripe_client).to receive(:create_payment_intent)
        .and_return(stripe_payment_intent)
    end

    it "creates a payment and returns the stripe client secret" do
      post "/payments/payments.json", params: { amount: 2000, currency: "usd" }

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)
      expect(json["amount"]).to eq(2000)
      expect(json["currency"]).to eq("usd")
      expect(json["status"]).to eq("pending")
      expect(json["stripe_payment_intent_id"]).to eq("pi_test_123")
      expect(json["stripe_client_secret"]).to eq("pi_test_123_secret_abc")
      expect(json["publishable_key"]).to be_present
    end

    it "uses default currency when not provided" do
      post "/payments/payments.json", params: { amount: 1500 }

      json = JSON.parse(response.body)
      expect(json["currency"]).to eq("usd")
    end

    it "returns 422 when amount is missing" do
      post "/payments/payments.json", params: { currency: "usd" }

      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json["error"]).to be_present
    end

    it "returns 422 when amount is invalid" do
      post "/payments/payments.json", params: { amount: -100 }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 402 when Stripe fails" do
      allow(stripe_client).to receive(:create_payment_intent)
        .and_raise(Stripe::InvalidRequestError.new("Invalid amount", :amount))

      post "/payments/payments.json", params: { amount: 2000 }

      expect(response).to have_http_status(:payment_required)
      json = JSON.parse(response.body)
      expect(json["error"]).to be_present
    end
  end

  describe "GET /payments/:id" do
    it "returns the payment details" do
      payment = OctoStripeGateway::Payment.create!(
        amount: 3000,
        currency: "eur",
        stripe_payment_intent_id: "pi_show_123",
        stripe_client_secret: "pi_show_123_secret"
      )

      get "/payments/payments/#{payment.id}.json"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["amount"]).to eq(3000)
      expect(json["currency"]).to eq("eur")
      expect(json["stripe_payment_intent_id"]).to eq("pi_show_123")
    end

    it "returns 404 for non-existent payment" do
      get "/payments/payments/999999.json"

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Payment not found")
    end
  end

  describe "PATCH /payments/:id/complete" do
    it "confirms a succeeded payment" do
      payment = OctoStripeGateway::Payment.create!(
        amount: 2000,
        currency: "usd",
        stripe_payment_intent_id: "pi_complete_123"
      )

      allow(stripe_client).to receive(:find_payment_intent)
        .and_return(stripe_payment_intent(status: "succeeded"))

      patch "/payments/payments/#{payment.id}/complete.json"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["status"]).to eq("paid")
      expect(json["paid_at"]).to be_present
    end

    it "returns pending when payment is not yet succeeded" do
      payment = OctoStripeGateway::Payment.create!(
        amount: 2000,
        currency: "usd",
        stripe_payment_intent_id: "pi_pending_123"
      )

      allow(stripe_client).to receive(:find_payment_intent)
        .and_return(stripe_payment_intent(status: "requires_action"))

      patch "/payments/payments/#{payment.id}/complete.json"

      json = JSON.parse(response.body)
      expect(json["status"]).to eq("pending")
    end
  end
end
