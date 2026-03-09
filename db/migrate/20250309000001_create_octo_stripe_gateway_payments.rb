# frozen_string_literal: true

class CreateOctoStripeGatewayPayments < ActiveRecord::Migration[8.0]
  def change
    create_table :osg_payments do |t|
      t.integer :amount, null: false
      t.string :currency, null: false, default: "usd"
      t.integer :status, null: false, default: 0
      t.string :stripe_payment_intent_id
      t.string :stripe_client_secret
      t.datetime :paid_at
      t.references :payable, polymorphic: true

      t.timestamps
    end

    add_index :osg_payments, :stripe_payment_intent_id
  end
end
