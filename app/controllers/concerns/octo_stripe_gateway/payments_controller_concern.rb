# frozen_string_literal: true

module OctoStripeGateway
  module PaymentsControllerConcern
    extend ActiveSupport::Concern

    included do
      before_action :set_payment, only: %i[show complete refund]
    end

    def create
      @payment = Payment.create!(payment_params)
      client_secret = @payment.create_payment_intent

      render json: @payment.as_octo_json(stripe_client_secret: client_secret), status: :created
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[OctoStripeGateway] Payment creation failed: #{e.message}")
      render json: { error: e.message }, status: :unprocessable_content
    rescue Stripe::StripeError => e
      Rails.logger.error("[OctoStripeGateway] Stripe error on create: #{e.message}")
      render json: { error: e.message }, status: :payment_required
    end

    def show
      render json: @payment.as_octo_json
    end

    def complete
      @payment.confirm_payment unless @payment.paid?

      render json: @payment.as_octo_json
    rescue Stripe::StripeError => e
      Rails.logger.error("[OctoStripeGateway] Stripe error on complete for payment #{@payment.id}: #{e.message}")
      render json: { error: e.message }, status: :bad_gateway
    end

    def refund
      @payment.refund_payment

      render json: @payment.as_octo_json
    rescue Stripe::StripeError => e
      Rails.logger.error("[OctoStripeGateway] Stripe error on refund for payment #{@payment.id}: #{e.message}")
      render json: { error: e.message }, status: :unprocessable_content
    end

    private

    def set_payment
      @payment = Payment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn("[OctoStripeGateway] Payment not found: #{params[:id]}")
      render json: { error: "Payment not found" }, status: :not_found
    end

    def payment_params
      params.permit(:amount, :currency)
    end
  end
end
