# frozen_string_literal: true

module StripeHelpers
  def stripe_payment_intent(status: "requires_payment_method", id: "pi_test_123")
    double("Stripe::PaymentIntent",
      id: id,
      object: "payment_intent",
      amount: 2000,
      currency: "usd",
      status: status,
      client_secret: "#{id}_secret_abc",
      last_payment_error: nil,
      metadata: {}
    )
  end

  def stripe_failed_intent(message: "Your card was declined.")
    error = double("PaymentError", message: message)
    double("Stripe::PaymentIntent",
      id: "pi_test_failed",
      object: "payment_intent",
      amount: 2000,
      currency: "usd",
      status: "requires_payment_method",
      client_secret: "pi_test_failed_secret",
      last_payment_error: error,
      metadata: {}
    )
  end
end
