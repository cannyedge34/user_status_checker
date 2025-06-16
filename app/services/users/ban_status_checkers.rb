# frozen_string_literal: true

module Users
  class BanStatusCheckers
    include Dry::Monads[:result]

    def initialize(
      country_checker: Users::BanStatusChecker::CountryChecker.new,
      rooted_device_checker: Users::BanStatusChecker::RootedDeviceChecker.new,
      privacy_tools_checker: Users::BanStatusChecker::PrivacyToolsChecker.new
    )
      @checkers = [country_checker, rooted_device_checker, privacy_tools_checker]
    end

    def call(country:, rooted_device:, ip:)
      checkers.each do |checker|
        result = checker.call(opts: { country:, rooted_device:, ip: })
        return Failure(result.failure) if result.failure?
      end

      Success()
    end

    private

    attr_reader :checkers
  end
end
