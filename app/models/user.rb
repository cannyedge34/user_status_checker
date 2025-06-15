# frozen_string_literal: true

class User < ApplicationRecord
  enum :ban_status, {
    banned: 'banned',
    not_banned: 'not_banned'
  }, prefix: :ban_status

  validates :ban_status, presence: true
  validates :idfa, presence: true, uniqueness: true
end
