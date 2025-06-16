# frozen_string_literal: true

module Users
  class ResponseParser
    include Dry::Monads[:result]

    def call(response_body)
      data = JSON.parse(response_body)
      Success(data)
    rescue JSON::ParserError => e
      Success(e)
    end
  end
end
