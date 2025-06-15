# frozen_string_literal: true

describe User do
  describe 'validations' do
    subject(:user) do
      build(
        :user,
        idfa:,
        ban_status:
      )
    end

    let(:idfa) { '8264148c-be95-4b2b-b260-6ee98dd53bf6' }
    let(:ban_status) { 'banned' }

    it 'is valid with valid attributes' do
      expect(user).to be_valid
    end

    describe 'validations' do
      describe 'idfa' do
        context 'with idfa' do
          it { is_expected.to be_valid }
        end

        context 'without idfa' do
          let(:idfa) { nil }

          it 'is not valid' do
            expect(user).not_to be_valid
          end

          it 'has errors' do
            user.save

            expect(user.errors.messages).to eq(
              idfa: ["can't be blank"]
            )
          end
        end
      end

      describe 'ban_status' do
        context 'with ban_status' do
          it { is_expected.to be_valid }
        end

        context 'without ban_status' do
          let(:ban_status) { nil }

          it 'is not valid' do
            expect(user).not_to be_valid
          end

          it 'has errors' do
            user.save

            expect(user.errors.messages).to eq(
              ban_status: ["can't be blank"]
            )
          end
        end

        it 'allows valid ban_statuses' do
          expect(described_class.ban_statuses.keys).to match_array(%w[banned not_banned])
        end
      end
    end
  end
end
