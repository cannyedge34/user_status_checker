# frozen_string_literal: true

module Users
  class DataSources
    def initialize(
      data_source_cache: Users::DataSource::Cache.new,
      third_party_api: Users::DataSource::ThirdPartyApi.new,
      cache: RedisHandler.new
    )
      @data_source_cache = data_source_cache
      @third_party_api = third_party_api
      @cache = cache
    end

    def call(ip:)
      cache.get("privacy_tools_check:#{ip}").present? ? data_source_cache : third_party_api
    end

    private

    attr_reader :data_source_cache, :third_party_api, :cache
  end
end
