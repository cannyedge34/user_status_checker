# frozen_string_literal: true

module Users
  class IntegrityLogPersister
    include Dry::Monads[:result]

    def call(user:, integrity_log_params:)
      if user.previously_new_record? || user.ban_status_previous_change == %w[not_banned banned]
        IntegrityLog.create!(
          idfa: user.idfa,
          ban_status: user.ban_status,
          ip: integrity_log_params[:ip],
          rooted_device: integrity_log_params[:rooted_device],
          country: integrity_log_params[:country]
        )

        # we can send here an event domain called integrity_log_created with delivery_boy gem
        # to to allow future re-routing of logs to other data sources, something like:

        # payload = {
        #   name: 'integrity_log_created',
        #   version: '1.0.0',
        #   data: {
        #     idfa: user.idfa,
        #     ban_status: user.ban_status,
        #     ip: integrity_log_params[:ip],
        #     rooted_device: integrity_log_params[:rooted_device],
        #     country: integrity_log_params[:country]
        #     created_at: integrity_log.created_at
        #   }
        # }

        # DeliveryBoy.deliver(payload.to_json, topic: Settings.kafka.topics.integrity_logs)

        # and other services/data sources would consume this event.
      end
      Success()
    end
  end
end
