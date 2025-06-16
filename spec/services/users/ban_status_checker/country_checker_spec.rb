# frozen_string_literal: true

describe Users::BanStatusChecker::CountryChecker do
  subject(:checker) { described_class.new }

  let(:redis) { instance_double(RedisHandler) }

  describe '#call' do
    subject(:result) { checker.call(opts: opts, redis: redis) }

    context 'when country is blank' do
      let(:opts) { { country: '' } }

      before do
        allow(redis).to receive(:member_of_set?)
      end

      it 'returns Success without calling Redis' do
        expect(result).to be_success
        expect(redis).not_to have_received(:member_of_set?)
      end
    end

    context 'when country is whitelisted' do
      let(:opts) { { country: 'US' } }

      before do
        allow(redis).to receive(:member_of_set?).with('whitelisted_countries', 'US').and_return(true)
      end

      it 'returns Success and checks Redis set' do
        expect(result).to be_success
        expect(redis).to have_received(:member_of_set?).with('whitelisted_countries', 'US')
      end
    end

    context 'when country is not whitelisted' do
      let(:opts) { { country: 'ZZ' } }

      before do
        allow(redis).to receive(:member_of_set?).with('whitelisted_countries', 'ZZ').and_return(false)
      end

      it 'returns Failure(:ban_reason_country) and checks Redis set' do
        expect(result).to be_failure
        expect(result.failure).to eq(:ban_reason_country)
        expect(redis).to have_received(:member_of_set?).with('whitelisted_countries', 'ZZ')
      end
    end
  end
end
