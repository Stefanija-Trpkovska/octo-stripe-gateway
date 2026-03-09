# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require_relative "test_app/config/environment"
require "rspec/rails"
require "webmock/rspec"
require_relative "support/stripe_helpers"

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.include StripeHelpers

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before do
    OctoStripeGateway.currency = "usd"
    OctoStripeGateway.stripe_api_key = "sk_test_default_key"
    OctoStripeGateway.stripe_publishable_key = "pk_test_default_key"
    OctoStripeGateway.stripe_webhook_secret = "whsec_test_secret"
  end
end
