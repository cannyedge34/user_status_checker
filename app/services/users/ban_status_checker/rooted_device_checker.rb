# frozen_string_literal: true

module Users
  module BanStatusChecker
    class RootedDeviceChecker
      include Dry::Monads[:result]

      def call(opts:)
        opts[:rooted_device] ? Failure(:ban_reason_rooted_device) : Success()
      end
    end
  end
end
