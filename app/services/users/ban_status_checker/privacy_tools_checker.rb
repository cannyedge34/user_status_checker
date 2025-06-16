# frozen_string_literal: true

module Users
  module BanStatusChecker
    class PrivacyToolsChecker
      include Dry::Monads[:result, :do]

      CACHE_TTL = 86_400 # 24 hours in seconds

      def initialize(cache: RedisHandler.new, parser: Users::ResponseParser.new, data_sources: Users::DataSources.new)
        @cache = cache
        @parser = parser
        @data_sources = data_sources
      end

      def call(opts:)
        ip = opts[:ip]

        return Success() if ip.blank?

        source = data_sources.call(ip:)

        result = source.call(ip:)

        set_cache(ip, result.value!) if source.instance_of?(Users::DataSource::ThirdPartyApi)

        parsed_result = yield parser.call(result.value!)

        privacy_tools_detected?(parsed_result) ? Failure(:ban_reason_vpn) : Success()
      end

      private

      attr_reader :cache, :parser, :data_sources

      def set_cache(ip, body)
        cache.set(cache_key(ip), body, expires_in: CACHE_TTL)
      end

      def cache_key(ip)
        "privacy_tools_check:#{ip}"
      end

      def privacy_tools_detected?(data)
        data.is_a?(Hash) ? data.dig('security', 'vpn') || data.dig('security', 'tor') : false
      end
    end
  end
end
