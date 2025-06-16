# frozen_string_literal: true

module Users
  class BanStatusProcessor
    include Dry::Monads[:result, :do]

    def initialize(user_params:, integrity_log_params:)
      @user_params = user_params
      @integrity_log_params = integrity_log_params
    end

    def call(
      user_persister: Users::UserPersister.new,
      integrity_log_persister: Users::IntegrityLogPersister.new,
      checkers: ::Users::BanStatusCheckers.new
    )
      user = find_or_initialize_user(user_params[:idfa])

      return Success(ban_status: user.ban_status) if user.ban_status_banned?

      ban_status = yield determine_ban_status(checkers:, integrity_log_params:)

      ActiveRecord::Base.transaction do
        user_persister.call(user:, ban_status:)
        integrity_log_persister.call(user:, integrity_log_params:)
      end

      Success(ban_status: ban_status)
    end

    private

    attr_reader :user_params, :integrity_log_params

    def find_or_initialize_user(idfa)
      User.find_or_initialize_by(idfa: idfa)
    end

    def determine_ban_status(checkers:, integrity_log_params:)
      result = checkers.call(
        country: integrity_log_params[:country],
        rooted_device: integrity_log_params[:rooted_device],
        ip: integrity_log_params[:ip]
      )

      result.failure? ? Success('banned') : Success('not_banned')
    end
  end
end
