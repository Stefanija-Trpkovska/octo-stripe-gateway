# frozen_string_literal: true

module OctoStripeGateway
  module PaymentsControllerConcern
    extend ActiveSupport::Concern

    included do
      before_action :set_payment, only: %i[show complete]
    end

    def create
      @payment = Payment.create!(
        amount: params[:amount],
        currency: params[:currency] || OctoStripeGateway.currency
      )
      @payment.create_payment_intent

      respond_to do |format|
        format.html
        format.json { render json: payment_response(@payment), status: :created }
      end
    end

    def show
      respond_to do |format|
        format.html
        format.json { render json: payment_response(@payment) }
      end
    end

    def complete
      @payment.confirm_payment unless @payment.paid?

      respond_to do |format|
        format.html
        format.json { render json: payment_response(@payment) }
      end
    end

    private

    def set_payment
      @payment = Payment.find(params[:id])
    end

    def payment_response(payment)
      {
        id: payment.id,
        amount: payment.amount,
        currency: payment.currency,
        status: payment.status,
        stripe_payment_intent_id: payment.stripe_payment_intent_id,
        stripe_client_secret: payment.stripe_client_secret,
        publishable_key: OctoStripeGateway.stripe_publishable_key,
        paid_at: payment.paid_at
      }
    end
  end
end
