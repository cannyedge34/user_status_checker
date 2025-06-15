# frozen_string_literal: true

module RequestHelpers
  def parsed_response
    JSON.parse(response.body)
  end

  def json_headers
    { 'CONTENT_TYPE' => 'application/json' }
  end

  def post_json(path, params = {}, headers = {})
    post path, params: params.to_json, headers: json_headers.merge(headers)
  end
end
