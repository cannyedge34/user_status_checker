# frozen_string_literal: true

require 'rails_helper'

describe Users::DataSources do
  subject(:data_sources) do
    described_class.new(data_source_cache: data_source_cache, third_party_api: third_party_api, cache: cache)
  end

  let(:data_source_cache) { instance_double(Users::DataSource::Cache) }
  let(:third_party_api) { instance_double(Users::DataSource::ThirdPartyApi) }
  let(:cache) { instance_double(RedisHandler) }
  let(:ip) { '1.2.3.4' }

  describe '#call' do
    context 'when data is present in the cache' do
      before do
        allow(cache).to receive(:get).with("privacy_tools_check:#{ip}").and_return('some_data')
      end

      it 'returns the data_source_cache' do
        result = data_sources.call(ip: ip)
        expect(result).to eq(data_source_cache)
      end
    end

    context 'when data is not present in the cache' do
      before do
        allow(cache).to receive(:get).with("privacy_tools_check:#{ip}").and_return(nil)
      end

      it 'returns the third_party_api' do
        result = data_sources.call(ip: ip)
        expect(result).to eq(third_party_api)
      end
    end
  end
end
