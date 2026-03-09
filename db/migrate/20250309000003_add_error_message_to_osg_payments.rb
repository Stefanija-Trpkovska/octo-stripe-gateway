# frozen_string_literal: true

class AddErrorMessageToOsgPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :osg_payments, :error_message, :string
  end
end
