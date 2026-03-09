# frozen_string_literal: true

module OctoStripeGateway
  module PaymentsControllerConcern
    extend ActiveSupport::Concern

    included do
      before_action :set_payment, only: %i[show complete]
    end

    def create
      @payment = Payment.create!(payment_params)
      @payment.create_payment_intent

      render json: payment_response(@payment), status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_content
    rescue Stripe::StripeError => e
      render json: { error: e.message }, status: :payment_required
    end

    def show
      render json: payment_response(@payment)
    end

    def complete
      @payment.confirm_payment unless @payment.paid?

      render json: payment_response(@payment)
    end

    private

    def set_payment
      @payment = Payment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Payment not found" }, status: :not_found
    end

    def payment_params
      params.permit(:amount, :currency).tap do |p|
        p[:currency] ||= OctoStripeGateway.currency
      end
    end

    def payment_response(payment)
      {
        id: payment.id,
        amount: payment.amount,
        currency: payment.currency,
        status: octo_status(payment.status),
        gateway: "stripe",
        stripePaymentIntentId: payment.stripe_payment_intent_id,
        stripeClientSecret: payment.stripe_client_secret,
        publishableKey: OctoStripeGateway.stripe_publishable_key,
        paidAt: payment.paid_at&.iso8601,
        errorMessage: payment.error_message
      }.compact
    end

    def octo_status(status)
      { "pending" => "PENDING", "paid" => "CONFIRMED", "failed" => "FAILED" }[status]
    end
  end
end
