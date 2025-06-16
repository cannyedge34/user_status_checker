# frozen_string_literal: true

describe Users::BanStatusChecker::PrivacyToolsChecker do
  subject(:checker) { described_class.new(cache: redis) }

  let(:redis_klass) { RedisHandler }
  let(:redis) { instance_double(redis_klass) }
  let(:ip) { '1.2.3.4' }
  let(:opts) { { ip: ip } }
  let(:redis_key) { "privacy_tools_check:#{ip}" }
  let(:cache_ttl) { 86_400 }
  let(:http_klass) { Net::HTTP }

  before do
    allow(redis_klass).to receive(:new).and_return(redis)
    allow(redis).to receive(:get).with(redis_key).and_return(nil)
    allow(redis).to receive(:set).and_return(nil)
  end

  describe '#call' do
    context 'when ip is not cached' do
      context 'when ip is not using vpn or tor' do
        around do |example|
          VCR.use_cassette('check-status/privacy_tool_api_vpn_false_tor_false') { example.run }
        end

        it 'returns Success' do
          result = checker.call(opts: opts)
          expect(result).to be_success
        end

        it 'caches the response in Redis' do
          checker.call(opts: opts)
          expect(redis).to have_received(:set).with(redis_key, kind_of(String), expires_in: cache_ttl)
        end
      end

      context 'when ip is not using vpn but is using tor' do
        around do |example|
          VCR.use_cassette('check-status/privacy_tool_api_vpn_false_tor_true') { example.run }
        end

        it 'returns Failure' do
          result = checker.call(opts: opts)
          expect(result).to be_failure
          expect(result.failure).to eq(:ban_reason_vpn)
        end

        it 'caches the response in Redis' do
          checker.call(opts: opts)
          expect(redis).to have_received(:set).with(redis_key, kind_of(String), expires_in: cache_ttl)
        end
      end

      context 'when ip is using vpn but is not using tor' do
        around do |example|
          VCR.use_cassette('check-status/privacy_tool_api_vpn_true_tor_false') { example.run }
        end

        it 'returns Failure' do
          result = checker.call(opts: opts)
          expect(result).to be_failure
          expect(result.failure).to eq(:ban_reason_vpn)
        end

        it 'caches the response in Redis' do
          checker.call(opts: opts)
          expect(redis).to have_received(:set).with(redis_key, kind_of(String), expires_in: cache_ttl)
        end
      end

      context 'when ip is using vpn and also using tor' do
        around do |example|
          VCR.use_cassette('check-status/privacy_tool_api_vpn_true_tor_true') { example.run }
        end

        it 'returns Failure' do
          result = checker.call(opts: opts)
          expect(result).to be_failure
          expect(result.failure).to eq(:ban_reason_vpn)
        end

        it 'caches the response in Redis' do
          checker.call(opts: opts)
          expect(redis).to have_received(:set).with(redis_key, kind_of(String), expires_in: cache_ttl)
        end
      end
    end

    context 'when result is already cached in Redis' do
      before do
        allow(http_klass).to receive(:get_response).and_return(nil)
      end

      context 'when vpn: true and tor: true in cache' do
        let(:cached_body) do
          {
            security: {
              vpn: true,
              tor: true
            }
          }.to_json
        end

        before do
          allow(redis).to receive(:get).with(redis_key).and_return(cached_body)
        end

        it 'returns Failure' do
          result = checker.call(opts: opts)
          expect(result).to be_failure
          expect(result.failure).to eq(:ban_reason_vpn)
        end

        it 'does not call http third party api' do
          checker.call(opts: opts)
          expect(http_klass).not_to have_received(:get_response)
        end
      end

      context 'when vpn: false and tor: true in cache' do
        let(:cached_body) do
          {
            security: {
              vpn: false,
              tor: true
            }
          }.to_json
        end

        before do
          allow(redis).to receive(:get).with(redis_key).and_return(cached_body)
        end

        it 'returns Failure' do
          result = checker.call(opts: opts)
          expect(result).to be_failure
          expect(result.failure).to eq(:ban_reason_vpn)
        end

        it 'does not call http third party api' do
          checker.call(opts: opts)
          expect(http_klass).not_to have_received(:get_response)
        end
      end

      context 'when vpn: true and tor: false in cache' do
        let(:cached_body) do
          {
            security: {
              vpn: true,
              tor: false
            }
          }.to_json
        end

        before do
          allow(redis).to receive(:get).with(redis_key).and_return(cached_body)
        end

        it 'returns Failure' do
          result = checker.call(opts: opts)
          expect(result).to be_failure
          expect(result.failure).to eq(:ban_reason_vpn)
        end

        it 'does not call http third party api' do
          checker.call(opts: opts)
          expect(http_klass).not_to have_received(:get_response)
        end
      end

      context 'when vpn: false and tor: false in cache' do
        let(:cached_body) do
          {
            security: {
              vpn: false,
              tor: false
            }
          }.to_json
        end

        before do
          allow(redis).to receive(:get).with(redis_key).and_return(cached_body)
        end

        it 'returns Success' do
          result = checker.call(opts: opts)
          expect(result).to be_success
        end

        it 'does not call http third party api' do
          checker.call(opts: opts)
          expect(http_klass).not_to have_received(:get_response)
        end
      end

      context 'when cached data is invalid JSON' do
        let(:invalid_json) { '{ this is not valid JSON' }

        before do
          allow(redis).to receive(:get).with(redis_key).and_return(invalid_json)
        end

        it 'returns Success as fallback' do
          result = checker.call(opts: opts)

          expect(result).to be_success
        end

        it 'does not call http third party api' do
          checker.call(opts: opts)
          expect(http_klass).not_to have_received(:get_response)
        end
      end
    end

    context 'when IP is blank' do
      let(:opts) { { ip: '' } }

      before do
        allow(http_klass).to receive(:get_response).and_return(nil)
      end

      it 'returns Success' do
        result = checker.call(opts: opts)
        expect(result).to be_success
      end

      it 'does not call redis' do
        checker.call(opts: opts)
        expect(redis).not_to have_received(:set)
      end

      it 'does not call http third party api' do
        checker.call(opts: opts)
        expect(http_klass).not_to have_received(:get_response)
      end
    end
  end
end
