# frozen_string_literal: true

FactoryBot.define do
  factory :integrity_log do
    idfa { Faker::Internet.uuid }
    ban_status { %w[banned not_banned].sample }
    ip { Faker::Internet.ip_v4_address }
    rooted_device { Faker::Boolean.boolean }
    country { Faker::Address.country_code }
    proxy { Faker::Boolean.boolean }
    vpn { Faker::Boolean.boolean }
    created_at { Faker::Time.backward(days: 7) }
  end
end
