# frozen_string_literal: true

describe IntegrityLog do
  describe 'validations' do
    subject(:integrity_log) do
      build(
        :integrity_log,
        idfa: idfa,
        ban_status: ban_status,
        ip: ip,
        rooted_device: rooted_device,
        country: country,
        proxy: proxy,
        vpn: vpn
      )
    end

    let(:idfa) { '8264148c-be95-4b2b-b260-6ee98dd53bf6' }
    let(:ban_status) { 'banned' }
    let(:ip) { '192.168.1.1' }
    let(:rooted_device) { false }
    let(:country) { 'US' }
    let(:proxy) { false }
    let(:vpn) { false }

    it 'is valid with valid attributes' do
      expect(integrity_log).to be_valid
    end

    describe 'idfa' do
      context 'with idfa' do
        it { is_expected.to be_valid }
      end

      context 'without idfa' do
        let(:idfa) { nil }

        it 'is not valid' do
          expect(integrity_log).not_to be_valid
        end

        it 'has errors' do
          integrity_log.save

          expect(integrity_log.errors.messages).to eq(
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
          expect(integrity_log).not_to be_valid
        end

        it 'has errors' do
          integrity_log.save

          expect(integrity_log.errors.messages).to eq(
            ban_status: ["can't be blank"]
          )
        end
      end

      it 'allows valid ban_statuses' do
        expect(described_class.ban_statuses.keys).to match_array(%w[banned not_banned])
      end
    end

    describe 'ip' do
      context 'with valid ip' do
        it { is_expected.to be_valid }
      end

      context 'with invalid ip' do
        let(:ip) { 'invalid_ip' }

        it 'is valid with nil ip' do
          integrity_log.save

          # Since we are using t.inet
          # PostgreSQL already internally validates that the value is a valid IP #<IPAddr>
          # with invalid values the field will be nil
          expect(integrity_log.ip).to be_nil
        end
      end

      context 'without ip' do
        let(:ip) { nil }

        it { is_expected.to be_valid }
      end
    end

    describe 'country' do
      context 'with valid country' do
        it { is_expected.to be_valid }
      end

      context 'with invalid country' do
        let(:country) { 'USA' }

        it 'has errors' do
          integrity_log.save

          expect(integrity_log.errors.messages).to eq(
            country: ['is the wrong length (should be 2 characters)']
          )
        end
      end

      context 'without country' do
        let(:country) { nil }

        it { is_expected.to be_valid }
      end

      context 'with empty country' do
        let(:country) { '' }

        it { is_expected.to be_valid }
      end
    end

    describe 'validations for booleans' do
      %i[rooted_device proxy vpn].each do |boolean_field|
        context "when #{boolean_field} is nil" do
          before { integrity_log.send("#{boolean_field}=", nil) }

          it "is not valid without #{boolean_field}" do
            expect(integrity_log).not_to be_valid
          end

          it "has errors without #{boolean_field}" do
            integrity_log.save

            expect(integrity_log.errors[boolean_field]).to include('is not included in the list')
          end
        end

        context "when #{boolean_field} is true" do
          it "is valid when #{boolean_field} is true" do
            integrity_log.send("#{boolean_field}=", true)
            expect(integrity_log).to be_valid
          end

          it "is valid when #{boolean_field} is false" do
            integrity_log.send("#{boolean_field}=", false)
            expect(integrity_log).to be_valid
          end
        end
      end
    end
  end
end
