# frozen_string_literal: true

module OctoStripeGateway
  class Payment < ApplicationRecord
    self.table_name = "osg_payments"

    include StripePaymentConcern

    OCTO_STATUSES = { "pending" => "PENDING", "paid" => "CONFIRMED", "failed" => "FAILED", "refunded" => "REFUNDED" }.freeze

    enum :status, { pending: "pending", paid: "paid", failed: "failed", refunded: "refunded" }

    belongs_to :payable, polymorphic: true, optional: true

    before_validation :set_default_currency, on: :create

    validates :amount, presence: true, numericality: { greater_than: 0 }
    validates :currency, presence: true

    def as_octo_json(stripe_client_secret: nil)
      {
        id: id,
        amount: amount,
        currency: currency,
        status: OCTO_STATUSES[status],
        gateway: "stripe",
        stripePaymentIntentId: stripe_payment_intent_id,
        stripeClientSecret: stripe_client_secret,
        publishableKey: OctoStripeGateway.stripe_publishable_key,
        paidAt: paid_at&.iso8601,
        refundedAt: refunded_at&.iso8601,
        errorMessage: error_message
      }.compact
    end

    private

    def set_default_currency
      self.currency ||= OctoStripeGateway.currency
    end
  end
end

