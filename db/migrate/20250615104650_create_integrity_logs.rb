# frozen_string_literal: true

class CreateIntegrityLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :integrity_logs do |t|
      t.string :idfa, null: false
      t.string :ban_status, null: false
      t.inet :ip
      t.boolean :rooted_device, null: false, default: false
      t.string :country, limit: 2
      t.boolean :proxy, null: false, default: false
      t.boolean :vpn, null: false, default: false

      t.datetime :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :integrity_logs, :idfa
    add_index :integrity_logs, :created_at
  end
end
