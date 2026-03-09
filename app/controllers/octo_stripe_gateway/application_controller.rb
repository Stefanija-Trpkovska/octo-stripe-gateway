# frozen_string_literal: true

module OctoStripeGateway
  class ApplicationController < ActionController::API
    before_action :authenticate_request

    private

    def authenticate_request
      if OctoStripeGateway.authenticate
        OctoStripeGateway.authenticate.call(request) || deny_access
      elsif OctoStripeGateway.api_gateway_key
        token = request.headers["Authorization"]&.remove("Bearer ")
        deny_access unless ActiveSupport::SecurityUtils.secure_compare(token.to_s, OctoStripeGateway.api_gateway_key)
      end
    end

    def deny_access
      Rails.logger.warn("[OctoStripeGateway] Unauthorized request from #{request.remote_ip}")
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
