# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    idfa { Faker::Internet.uuid }
    ban_status { %w[banned not_banned].sample }
  end
end
