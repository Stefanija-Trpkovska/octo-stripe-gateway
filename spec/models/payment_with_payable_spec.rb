# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Payment with payable", type: :model do
  let(:booking) { Booking.create!(name: "Test Booking", total: 100.00) }
  let(:stripe_client) { instance_double(OctoStripeGateway::StripeClient) }

  before do
    allow(OctoStripeGateway::StripeClient).to receive(:new).and_return(stripe_client)
  end

  it "can be attached to a booking" do
    payment = OctoStripeGateway::Payment.create!(
      amount: 10000,
      currency: "usd",
      payable: booking
    )

    expect(payment.payable).to eq(booking)
    expect(booking.payments).to include(payment)
  end

  it "creates a payment intent for a booking" do
    allow(stripe_client).to receive(:create_payment_intent)
      .and_return(stripe_payment_intent(id: "pi_booking_123"))

    payment = OctoStripeGateway::Payment.create!(
      amount: 10000,
      currency: "usd",
      payable: booking
    )
    payment.create_payment_intent

    expect(payment.reload.stripe_payment_intent_id).to eq("pi_booking_123")
    expect(payment.payable).to eq(booking)
  end
end
