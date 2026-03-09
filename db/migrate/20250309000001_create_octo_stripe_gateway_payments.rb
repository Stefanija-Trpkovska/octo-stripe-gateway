# frozen_string_literal: true

class CreateOctoStripeGatewayPayments < ActiveRecord::Migration[8.0]
  def change
    create_enum :osg_payment_status, %w[pending paid failed refunded]

    create_table :osg_payments do |t|
      t.integer :amount, null: false
      t.string :currency, null: false, default: "usd"
      t.enum :status, enum_type: :osg_payment_status, null: false, default: "pending"
      t.string :stripe_payment_intent_id
      t.string :error_message
      t.datetime :paid_at
      t.datetime :refunded_at
      t.references :payable, polymorphic: true

      t.timestamps
    end

    add_index :osg_payments, :stripe_payment_intent_id, unique: true
  end
end
