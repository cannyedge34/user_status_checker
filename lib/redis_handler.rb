# frozen_string_literal: true

class RedisHandler
  def initialize(redis_client: Redis.current)
    @redis_client = redis_client
  end

  delegate :get, :keys, to: :redis_client

  def set(key, value, expires_in: nil)
    expires_in ? redis_client.setex(key, expires_in, value) : redis_client.set(key, value)
  end

  def member_of_set?(set, member)
    redis_client.sismember(set, member)
  end

  def del(*keys)
    redis_client.del(*keys)
  end

  private

  attr_reader :redis_client
end
