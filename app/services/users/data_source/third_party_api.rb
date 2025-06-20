# frozen_string_literal: true

module Users
  module DataSource
    class ThirdPartyApi
      include Dry::Monads[:result]

      VPN_API_URL = 'https://vpnapi.io/api/'
      API_KEY = Rails.application.credentials.dig(Rails.env.to_sym, :vpnapi, :key)

      def call(ip:)
        uri = URI("#{VPN_API_URL}#{ip}?key=#{API_KEY}")
        result = Net::HTTP.get_response(uri)
        Success(result.body)
      end
    end
  end
end
