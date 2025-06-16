# frozen_string_literal: true

module V1
  class UserController < ApplicationController
    include Dry::Monads[:result]

    def check_status
      result = Users::BanStatusProcessor.new(
        user_params:,
        integrity_log_params:
      ).call

      case result
      in Success(ban_status)
        render json: ban_status
      else
        render json: { error: 'unknown_error' }, status: :bad_request
      end
    end

    private

    def user_params
      params.permit(:idfa)
    end

    def integrity_log_params
      params.permit(:rooted_device).merge(ip: request.remote_ip, country: request.env['HTTP_CF_IPCOUNTRY'])
    end
  end
end
