# frozen_string_literal: true

describe Users::IntegrityLogPersister do
  describe '#call' do
    subject(:persister) { described_class.new }

    let(:integrity_log_params) do
      {
        ip: '1.2.3.4',
        rooted_device: false,
        country: 'ES'
      }
    end

    context 'when user is a new record' do
      let(:user) do
        build(:user, idfa: 'abc', ban_status: 'not_banned').tap do |u|
          allow(u).to receive_messages(previously_new_record?: true, ban_status_previous_change: nil)
        end
      end

      it 'creates an IntegrityLog record' do
        expect do
          persister.call(user: user, integrity_log_params: integrity_log_params)
        end.to change(IntegrityLog, :count).by(1)
      end

      it 'returns a Success' do
        result = persister.call(user: user, integrity_log_params: integrity_log_params)
        expect(result).to be_success
      end
    end

    context 'when ban_status has changed from not_banned to banned' do
      let(:user) do
        create(:user, idfa: 'abc', ban_status: 'not_banned').tap do |u|
          allow(u).to receive_messages(previously_new_record?: false,
                                       ban_status_previous_change: %w[not_banned
                                                                      banned])
        end
      end

      it 'creates an IntegrityLog record' do
        expect do
          persister.call(user: user, integrity_log_params: integrity_log_params)
        end.to change(IntegrityLog, :count).by(1)
      end

      it 'returns a Success' do
        result = persister.call(user: user, integrity_log_params: integrity_log_params)
        expect(result).to be_success
      end
    end

    context 'when user is not new and ban_status has not changed' do
      let(:user) do
        create(:user, idfa: 'abc', ban_status: 'not_banned').tap do |u|
          allow(u).to receive_messages(previously_new_record?: false, ban_status_previous_change: nil)
        end
      end

      it 'does not create an IntegrityLog record' do
        expect do
          persister.call(user: user, integrity_log_params: integrity_log_params)
        end.not_to change(IntegrityLog, :count)
      end

      it 'returns a Success' do
        result = persister.call(user: user, integrity_log_params: integrity_log_params)
        expect(result).to be_success
      end
    end

    context 'when create! raises an error' do
      let(:user) do
        build(:user, idfa: nil, ban_status: 'not_banned').tap do |u|
          allow(u).to receive_messages(previously_new_record?: true, ban_status_previous_change: nil)
        end
      end

      it 'raises ActiveRecord::RecordInvalid' do
        expect do
          persister.call(user: user, integrity_log_params: integrity_log_params)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
