# frozen_string_literal: true

# require 'rails_helper'
require 'webmock/rspec'

describe Users::DataSource::ThirdPartyApi do
  describe '#call' do
    subject(:service) { described_class.new }

    let(:ip) { '1.2.3.4' }
    let(:api_key) { 'fake-api-key' }
    let(:api_url) { "https://vpnapi.io/api/#{ip}?key=#{api_key}" }
    let(:response_body) { '{"security":{"vpn":false,"tor":false}}' }

    before do
      allow(Rails.application.credentials).to receive(:dig).with(Rails.env.to_sym, :vpnapi, :key).and_return(api_key)
    end

    context 'when the API call is successful' do
      before do
        stub_request(:get, api_url).to_return(status: 200, body: response_body)
      end

      it 'returns a Success monad with the response body' do
        result = service.call(ip: ip)

        expect(result).to be_success
        expect(result.value!).to eq(response_body)
      end
    end

    context 'when the API call fails with a 500 error' do
      before do
        stub_request(:get, api_url).to_return(status: 500, body: 'Internal Server Error')
      end

      it 'returns a Success monad with the error body (still considered success by design)' do
        result = service.call(ip: ip)

        expect(result).to be_success
        expect(result.value!).to eq('Internal Server Error')
      end
    end
  end
end
