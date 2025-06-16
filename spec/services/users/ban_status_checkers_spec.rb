# frozen_string_literal: true

describe Users::BanStatusCheckers do
  subject(:service_call) do
    described_class.new(
      country_checker: country_checker_instance,
      rooted_device_checker: rooted_device_checker_instance,
      privacy_tools_checker: privacy_tools_checker_instance
    ).call(country:, rooted_device:, ip:)
  end

  let(:country) { 'ES' }
  let(:rooted_device) { true }
  let(:ip) { '1.2.3.4' }

  let(:country_checker_instance) { instance_double(Users::BanStatusChecker::CountryChecker) }
  let(:rooted_device_checker_instance) { instance_double(Users::BanStatusChecker::RootedDeviceChecker) }
  let(:privacy_tools_checker_instance) { instance_double(Users::BanStatusChecker::PrivacyToolsChecker) }

  context 'when all checkers return Success' do
    before do
      allow(country_checker_instance).to receive(:call).and_return(Dry::Monads::Success(nil))
      allow(rooted_device_checker_instance).to receive(:call).and_return(Dry::Monads::Success(nil))
      allow(privacy_tools_checker_instance).to receive(:call).and_return(Dry::Monads::Success(nil))
    end

    it 'calls all checkers in order and returns Success' do
      expect(service_call).to be_success

      expect(country_checker_instance).to have_received(:call).with(opts: { country:, rooted_device:, ip: })
      expect(rooted_device_checker_instance).to have_received(:call).with(opts: { country:, rooted_device:, ip: })
      expect(privacy_tools_checker_instance).to have_received(:call).with(opts: { country:, rooted_device:, ip: })
    end
  end

  context 'when country_checker returns Failure' do
    before do
      allow(country_checker_instance).to receive(:call).and_return(Dry::Monads::Failure(:ban_reason_country))
      allow(rooted_device_checker_instance).to receive(:call)
      allow(privacy_tools_checker_instance).to receive(:call)
    end

    it 'returns early with Failure and skips other checkers' do
      expect(service_call.failure).to eq(:ban_reason_country)

      expect(rooted_device_checker_instance).not_to have_received(:call)
      expect(privacy_tools_checker_instance).not_to have_received(:call)
    end
  end

  context 'when country_checker returns Success and rooted_device_checker returns Failure' do
    before do
      allow(country_checker_instance).to receive(:call).and_return(Dry::Monads::Success(nil))
      allow(
        rooted_device_checker_instance
      ).to receive(:call).and_return(Dry::Monads::Failure(:ban_reason_rooted_device))
      allow(privacy_tools_checker_instance).to receive(:call)
    end

    it 'returns Failure and skips privacy_tools_checker' do
      expect(service_call.failure).to eq(:ban_reason_rooted_device)

      expect(privacy_tools_checker_instance).not_to have_received(:call)
    end
  end

  context 'when country and rooted_device checkers return Success but privacy_tools_checker returns Failure' do
    before do
      allow(country_checker_instance).to receive(:call).and_return(Dry::Monads::Success(nil))
      allow(rooted_device_checker_instance).to receive(:call).and_return(Dry::Monads::Success(nil))
      allow(privacy_tools_checker_instance).to receive(:call).and_return(Dry::Monads::Failure(:ban_reason_vpn))
    end

    it 'returns Failure from privacy_tools_checker' do
      expect(service_call.failure).to eq(:ban_reason_vpn)
    end
  end
end
