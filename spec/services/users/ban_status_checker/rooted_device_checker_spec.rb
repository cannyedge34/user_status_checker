# frozen_string_literal: true

describe Users::BanStatusChecker::RootedDeviceChecker do
  subject(:checker) { described_class.new }

  describe '#call' do
    context 'when rooted_device is true' do
      let(:opts) { { rooted_device: true } }

      it 'returns Failure with :ban_reason_rooted_device' do
        result = checker.call(opts: opts)
        expect(result).to be_failure
        expect(result.failure).to eq(:ban_reason_rooted_device)
      end
    end

    context 'when rooted_device is false' do
      let(:opts) { { rooted_device: false } }

      it 'returns Success' do
        result = checker.call(opts: opts)
        expect(result).to be_success
      end
    end
  end
end
