class Booking < ApplicationRecord
  has_many :payments,
    class_name: "OctoStripeGateway::Payment",
    as: :payable
end
