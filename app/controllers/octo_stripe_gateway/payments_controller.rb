# frozen_string_literal: true

module OctoStripeGateway
  class PaymentsController < ApplicationController
    include ::OctoStripeGateway::PaymentsControllerConcern
  end
end
