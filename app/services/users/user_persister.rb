# frozen_string_literal: true

module Users
  class UserPersister
    include Dry::Monads[:result]

    def call(user:, ban_status:)
      user.assign_attributes(ban_status:)
      user.save!
      Success()
    end
  end
end
