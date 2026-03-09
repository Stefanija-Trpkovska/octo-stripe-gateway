# frozen_string_literal: true

module OctoStripeGateway
  class WebhooksController < ApplicationController
    skip_before_action :authenticate_request

    include ::OctoStripeGateway::WebhooksControllerConcern
  end
end
