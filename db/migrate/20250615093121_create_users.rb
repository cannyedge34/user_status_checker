# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :idfa, null: false
      t.string :ban_status, null: false
      t.timestamps
    end

    add_index :users, :idfa, unique: true
  end
end
