# frozen_string_literal: true

class CreateBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :bookings do |t|
      t.string :name
      t.decimal :total, precision: 10, scale: 2
      t.timestamps
    end
  end
end
