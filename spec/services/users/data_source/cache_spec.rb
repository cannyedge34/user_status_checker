# frozen_string_literal: true

describe Users::DataSource::Cache do
  subject(:data_source_cache) { described_class.new(cache: cache) }

  let(:cache) { instance_double(Redis) }
  let(:ip) { '1.2.3.4' }

  describe '#call' do
    context 'when the IP is cached' do
      let(:cached_data) { '{"vpn":false,"tor":false}' }

      before do
        allow(cache).to receive(:get).with("privacy_tools_check:#{ip}").and_return(cached_data)
      end

      it 'returns a Success monad with the cached data' do
        result = data_source_cache.call(ip: ip)
        expect(result).to be_success
        expect(result.value!).to eq(cached_data)
      end
    end

    context 'when the IP is not cached' do
      before do
        allow(cache).to receive(:get).with("privacy_tools_check:#{ip}").and_return(nil)
      end

      it 'returns a Success monad with nil' do
        result = data_source_cache.call(ip: ip)
        expect(result).to be_success
        expect(result.value!).to be_nil
      end
    end
  end
end
