# frozen_string_literal: true

describe Users::UserPersister do
  subject(:persister) { described_class.new }

  let(:user) { build(:user) }

  describe '#call' do
    context 'when user is saved successfully' do
      it 'assigns ban_status and returns Success' do
        result = persister.call(user: user, ban_status: 'banned')

        expect(result).to be_success
        expect(user.ban_status).to eq('banned')
        expect(user).to be_persisted
      end
    end

    context 'when saving the user raises an error' do
      let(:invalid_user) { build(:user, idfa: nil) }

      it 'raises ActiveRecord::RecordInvalid' do
        expect do
          persister.call(user: invalid_user, ban_status: 'banned')
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
