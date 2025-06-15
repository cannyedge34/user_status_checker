# frozen_string_literal: true

require 'redis'

AppRedisClient = Redis.new(
  url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'),
  reconnect_attempts: 3,
  timeout: 5,
  driver: :ruby
)

Redis.define_singleton_method(:current) { AppRedisClient }
