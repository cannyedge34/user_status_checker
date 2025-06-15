# frozen_string_literal: true

class IntegrityLog < ApplicationRecord
  validates :idfa, :ban_status, presence: true
  validates :country, length: { is: 2 }, allow_blank: true
  validates :rooted_device, :proxy, :vpn, inclusion: { in: [true, false] }

  enum :ban_status, { banned: 'banned', not_banned: 'not_banned' }
end
