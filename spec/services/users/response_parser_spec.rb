# frozen_string_literal: true

describe Users::ResponseParser do
  subject(:parser) { described_class.new }

  describe '#call' do
    context 'when the response_body is a valid JSON' do
      let(:json_body) { '{"security": {"vpn": false, "tor": false}}' }

      it 'returns Success with the parsed data' do
        result = parser.call(json_body)
        expect(result).to be_success
        expect(result.value!).to eq({ 'security' => { 'vpn' => false, 'tor' => false } })
      end
    end

    context 'when the response_body is invalid JSON' do
      let(:invalid_body) { '{ this is not valid JSON' }

      it 'returns Success with a JSON::ParserError' do
        result = parser.call(invalid_body)

        expect(result).to be_success
        expect(result.value!).to be_a(JSON::ParserError)
        expect(result.value!.message).to match('expected object key, got \'this\' at line 1 column 3')
      end
    end
  end
end
