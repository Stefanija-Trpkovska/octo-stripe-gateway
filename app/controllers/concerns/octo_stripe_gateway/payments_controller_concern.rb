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

      respond_to do |format|
        format.html { render :create }
        format.json { render json: payment_response(@payment), status: :created }
      end
    rescue ActiveRecord::RecordInvalid => e
      respond_to do |format|
        format.html { render :new }
        format.json { render json: { error: e.message }, status: :unprocessable_content }
      end
    rescue Stripe::StripeError => e
      respond_to do |format|
        format.html { render :new }
        format.json { render json: { error: e.message }, status: :payment_required }
      end
    end

    def show
      respond_to do |format|
        format.html { render :show }
        format.json { render json: payment_response(@payment) }
      end
    end

    def complete
      @payment.confirm_payment unless @payment.paid?

      respond_to do |format|
        format.html { render :complete }
        format.json { render json: payment_response(@payment) }
      end
    end

    private

    def set_payment
      @payment = Payment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { redirect_to root_path }
        format.json { render json: { error: "Payment not found" }, status: :not_found }
      end
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
        status: payment.status,
        gateway: "stripe",
        stripePaymentIntentId: payment.stripe_payment_intent_id,
        stripeClientSecret: payment.stripe_client_secret,
        publishableKey: OctoStripeGateway.stripe_publishable_key,
        paidAt: payment.paid_at,
        errorMessage: payment.error_message
      }.compact
    end
  end
end
