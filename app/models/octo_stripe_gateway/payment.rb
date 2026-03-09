# frozen_string_literal: true

module OctoStripeGateway
  class Payment < ApplicationRecord
    self.table_name = "osg_payments"

    enum :status, { pending: "pending", paid: "paid", failed: "failed", refunded: "refunded" }

    belongs_to :payable, polymorphic: true, optional: true

    validates :amount, presence: true, numericality: { greater_than: 0 }
    validates :currency, presence: true

    def stripe_client
      @stripe_client ||= StripeClient.new
    end

    def create_payment_intent
      return if stripe_payment_intent_id.present?

      intent = stripe_client.create_payment_intent(amount, currency)
      update!(
        stripe_payment_intent_id: intent.id,
        stripe_client_secret: intent.client_secret
      )
    end

    def refund_payment
      return unless paid?

      stripe_client.refund_payment_intent(stripe_payment_intent_id)
      update!(status: :refunded, refunded_at: Time.current)
    end

    def confirm_payment
      return if paid?

      intent = stripe_client.find_payment_intent(stripe_payment_intent_id)

      case intent.status
      when "succeeded"
        update!(status: :paid, paid_at: Time.current)
      when "canceled", "requires_payment_method"
        message = intent.last_payment_error&.message || "Payment #{intent.status}"
        update!(status: :failed, error_message: message)
      end
    end
  end
end
