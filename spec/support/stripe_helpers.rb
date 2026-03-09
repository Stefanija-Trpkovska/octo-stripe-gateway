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

  def stripe_refund(payment_intent_id: "pi_test_123")
    double("Stripe::Refund",
      id: "re_test_123",
      object: "refund",
      amount: 2000,
      payment_intent: payment_intent_id,
      status: "succeeded"
    )
  end

  def stripe_charge_refunded_event(payment_intent_id:)
    Stripe::Event.construct_from(
      "id" => "evt_test_#{SecureRandom.hex(8)}",
      "type" => "charge.refunded",
      "data" => {
        "object" => {
          "id" => "ch_test_#{SecureRandom.hex(8)}",
          "object" => "charge",
          "payment_intent" => payment_intent_id,
          "refunded" => true,
          "amount_refunded" => 2000
        }
      }
    )
  end

  def stripe_webhook_event(type:, payment_intent_id:, error_message: nil)
    payment_intent_data = {
      "id" => payment_intent_id,
      "object" => "payment_intent",
      "amount" => 2000,
      "currency" => "usd",
      "status" => type == "payment_intent.succeeded" ? "succeeded" : "requires_payment_method"
    }

    if error_message
      payment_intent_data["last_payment_error"] = { "message" => error_message }
    end

    Stripe::Event.construct_from(
      "id" => "evt_test_#{SecureRandom.hex(8)}",
      "type" => type,
      "data" => { "object" => payment_intent_data }
    )
  end
end
