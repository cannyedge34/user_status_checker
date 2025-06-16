# frozen_string_literal: true

module Users
  module BanStatusChecker
    class CountryChecker
      include Dry::Monads[:result]

      def call(opts:, redis: RedisHandler.new)
        country = opts[:country]
        if country.blank? || redis.member_of_set?('whitelisted_countries', opts[:country])
          Success()
        else
          Failure(:ban_reason_country)
        end
      end
    end
  end
end
