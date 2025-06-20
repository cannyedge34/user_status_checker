# frozen_string_literal: true

module Users
  module DataSource
    class Cache
      include Dry::Monads[:result]

      def initialize(cache: RedisHandler.new)
        @cache = cache
      end

      def call(ip:)
        Success(cache.get("privacy_tools_check:#{ip}"))
      end

      private

      attr_reader :cache
    end
  end
end
