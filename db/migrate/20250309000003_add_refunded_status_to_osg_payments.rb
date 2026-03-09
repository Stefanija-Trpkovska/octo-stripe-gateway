# frozen_string_literal: true

class AddRefundedStatusToOsgPayments < ActiveRecord::Migration[8.0]
  def up
    execute "ALTER TYPE osg_payment_status ADD VALUE 'refunded'"
    add_column :osg_payments, :refunded_at, :datetime
  end

  def down
    remove_column :osg_payments, :refunded_at
  end
end
