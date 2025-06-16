# frozen_string_literal: true

require 'rails_helper'

describe Users::BanStatusProcessor do
  subject(:service_call) do
    described_class.new(user_params:, integrity_log_params:).call
  end

  let(:idfa) { '8264148c-be95-4b2b-b260-6ee98dd53bf6' }
  let(:rooted_device) { true }
  let(:ip) { '1.2.3.4' }
  let(:country) { 'ES' }

  let(:user_params) { { idfa: } }
  let(:integrity_log_params) { { rooted_device:, ip:, country: } }

  let(:checkers_klass) { Users::BanStatusCheckers }
  let(:checkers_instance) { instance_double(checkers_klass) }

  let(:integrity_log_persister_klass) { Users::IntegrityLogPersister }
  let(:integrity_log_persister_instance) do
    instance_double(integrity_log_persister_klass, call: Dry::Monads::Success())
  end

  let(:user_persister_klass) { Users::UserPersister }
  let(:user_persister_instance) { instance_double(user_persister_klass, call: Dry::Monads::Success()) }

  let(:user_klass) { User }
  let(:user_instance) { User.new }

  before do
    allow(checkers_klass).to receive(:new).and_return(checkers_instance)
    allow(integrity_log_persister_klass).to receive(:new).and_return(integrity_log_persister_instance)
    allow(user_persister_klass).to receive(:new).and_return(user_persister_instance)
    allow(user_klass).to receive(:find_or_initialize_by).and_return(user_instance)
  end

  context 'when user does not exist' do
    context 'when checkers returns Success' do
      let(:ban_status) { 'not_banned' }

      before do
        allow(checkers_instance).to receive(:call).and_return(Dry::Monads::Success())
      end

      it 'calls the ban_status_checkers once' do
        service_call

        expect(checkers_instance).to have_received(:call).with(
          country: country,
          rooted_device: rooted_device,
          ip: ip
        ).once
      end

      it 'returns not_banned ban_status' do
        expect(service_call.value!).to eq({ ban_status: })
      end

      it 'calls the user_persister instance' do
        service_call

        expect(user_persister_instance).to have_received(:call).with(user: user_instance, ban_status:)
      end

      it 'calls the integrity logger' do
        service_call

        expect(integrity_log_persister_instance).to have_received(:call).with(
          user: user_instance,
          integrity_log_params: integrity_log_params
        )
      end
    end

    context 'when checkers returns Failure' do
      let(:ban_status) { 'banned' }

      before do
        allow(checkers_instance).to receive(:call).and_return(Dry::Monads::Failure(:ban_reason_country))
      end

      it 'returns banned ban_status' do
        expect(service_call.value!).to eq({ ban_status: })
      end

      it 'calls the user_persister instance' do
        service_call

        expect(user_persister_instance).to have_received(:call).with(user: user_instance, ban_status:)
      end

      it 'calls the integrity logger' do
        service_call

        expect(integrity_log_persister_instance).to have_received(:call).with(
          user: user_instance,
          integrity_log_params: integrity_log_params
        )
      end
    end
  end

  context 'when user exists with banned ban_status' do
    let(:ban_status) { 'banned' }
    let!(:user) { create(:user, idfa:, ban_status:) }

    before do
      allow(user_klass).to receive(:find_or_initialize_by).and_return(user)
      allow(checkers_instance).to receive(:call).and_return(Dry::Monads::Failure)
    end

    it 'does not call checkers' do
      service_call

      expect(checkers_instance).not_to have_received(:call)
    end

    it 'does not call the integrity log persister' do
      service_call

      expect(integrity_log_persister_instance).not_to have_received(:call)
    end

    it 'returns banned ban_status' do
      expect(service_call.value!).to eq({ ban_status: })
    end
  end

  context 'when user exists with not_banned ban_status' do
    let(:ban_status) { 'not_banned' }
    let!(:created_user) { create(:user, idfa:, ban_status:) }

    before do
      allow(user_klass).to receive(:find_or_initialize_by).and_return(created_user)
    end

    context 'when checkers returns Success' do
      before do
        allow(checkers_instance).to receive(:call).and_return(Dry::Monads::Success())
      end

      it 'returns not_banned ban_status' do
        expect(service_call.value!).to eq({ ban_status: })
      end

      it 'calls the integrity log persister instance' do
        service_call

        expect(integrity_log_persister_instance).to have_received(:call).with(
          user: created_user,
          integrity_log_params: integrity_log_params
        )
      end

      it 'calls the user persister instance' do
        service_call

        expect(user_persister_instance).to have_received(:call).with(
          user: created_user, ban_status:
        )
      end
    end

    context 'when checkers returns Failure' do
      before do
        allow(checkers_instance).to receive(:call).and_return(Dry::Monads::Failure(:ban_reason_country))
      end

      it 'returns banned ban_status' do
        expect(service_call.value!).to eq({ ban_status: 'banned' })
      end

      it 'calls the user persister instance' do
        service_call

        expect(user_persister_instance).to have_received(:call).with(
          user: created_user,
          ban_status: 'banned'
        )
      end

      it 'calls the integrity integrity_log_persister_instance' do
        service_call

        expect(integrity_log_persister_instance).to have_received(:call).with(
          user: created_user,
          integrity_log_params: integrity_log_params
        )
      end
    end
  end

  context 'when when integrity_log persister fails' do
    before do
      allow(checkers_instance).to receive(:call).and_return(Dry::Monads::Failure(:ban_reason_country))
      allow(user_persister_instance).to receive(:call) do |user:, **|
        user.assign_attributes(ban_status: 'banned', idfa:)
        user.save!
        Dry::Monads::Success()
      end
      allow(integrity_log_persister_instance).to receive(:call)
        .and_raise(ActiveRecord::RecordInvalid.new(IntegrityLog.new))
    end

    it 'rolls back user persistence if integrity_log_persister fails' do
      expect do
        service_call
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(User.all).to be_empty
    end
  end
end
