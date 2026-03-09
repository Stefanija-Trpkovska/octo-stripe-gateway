# frozen_string_literal: true

module OctoStripeGateway
  class WebhooksController < ApplicationController
    include ::OctoStripeGateway::WebhooksControllerConcern
  end
end
