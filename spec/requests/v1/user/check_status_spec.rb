# frozen_string_literal: true

describe 'V1::User#check_status', type: :request do
  let(:idfa) { '8264148c-be95-4b2b-b260-6ee98dd53bf6' }
  let(:params) { { idfa:, rooted_device: } }
  let(:remote_address) { '1.2.3.4' }
  let(:redis_handler_instance) { RedisHandler.new }
  let(:country) { 'ES' }
  let(:member_result) { true }
  let(:ip) { '1.2.3.4' }
  let(:redis_key) { "privacy_tools_check:#{ip}" }
  let(:cache_ttl) { 86_400 }

  shared_examples 'expects_user_is_created_with_status' do |expected_status|
    it 'expects user is created with expected status' do
      expect do
        post_json '/v1/user/check_status', params, { 'CF-IPCountry' => country, 'REMOTE_ADDR' => remote_address }
      end.to change(User, :count).by(1)

      user = User.find_by(idfa:)
      expect(user).to have_attributes(idfa:, ban_status: expected_status)
    end
  end

  shared_examples 'expects_integrity_log_is_created_with_status' do |expected_status|
    it 'expects integrity log is created with status' do
      expect do
        post_json '/v1/user/check_status', params, { 'CF-IPCountry' => country, 'REMOTE_ADDR' => remote_address }
      end.to change(IntegrityLog, :count).by(1)

      integrity_log = IntegrityLog.find_by(idfa:)
      expect(integrity_log).to have_attributes(
        idfa:,
        ban_status: expected_status,
        ip: be_a_valid_ip,
        rooted_device: rooted_device,
        country: country,
        proxy: false,
        vpn: false
      )
    end
  end

  shared_examples 'expects_user_is_updated_with_status' do |expected_status|
    it 'expects user is updated with status' do
      expect do
        post_json '/v1/user/check_status', params, { 'CF-IPCountry' => country, 'REMOTE_ADDR' => remote_address }
      end.not_to change(User, :count)

      user = User.find_by(idfa:)
      expect(user).to have_attributes(idfa:, ban_status: expected_status)
    end
  end

  shared_examples 'expects_user_is_not_updated' do |expected_status|
    it 'expects user is not updated' do
      expect do
        post_json '/v1/user/check_status', params, { 'CF-IPCountry' => country, 'REMOTE_ADDR' => remote_address }
      end.not_to change(User, :count)

      user = User.find_by(idfa:)
      expect(user).to have_attributes(idfa:, ban_status: expected_status)
    end
  end

  shared_examples 'expects_integrity_log_is_not_created' do
    it 'expects integrity_log is not created' do
      expect do
        post_json '/v1/user/check_status', params, { 'CF-IPCountry' => country, 'REMOTE_ADDR' => remote_address }
      end.not_to change(IntegrityLog, :count)
    end
  end

  shared_examples 'creates_a_cache_key_value_pair' do
    it 'creates a cache key value pair' do
      keys_before_request = redis_handler_instance.keys('privacy_tools_check:*')
      expect(keys_before_request).to be_empty

      post_json '/v1/user/check_status', params, { 'CF-IPCountry' => country, 'REMOTE_ADDR' => remote_address }

      keys_after_request = redis_handler_instance.keys('privacy_tools_check:*')
      expect(keys_after_request.size).to eq(1)
      expect(keys_after_request.first).to eq("privacy_tools_check:#{remote_address}")

      value = redis_handler_instance.get(keys_after_request.first)
      expect(value).not_to be_nil
    end
  end

  shared_examples 'does_not_create_a_cache_key_value_pair' do
    it 'does not create a cache key value pair' do
      keys_before_request = redis_handler_instance.keys('privacy_tools_check:*')
      expect(keys_before_request).to contain_exactly("privacy_tools_check:#{remote_address}")
      expect(keys_before_request.size).to eq(1)

      post_json '/v1/user/check_status', params, { 'CF-IPCountry' => country, 'REMOTE_ADDR' => remote_address }

      keys_after_request = redis_handler_instance.keys('privacy_tools_check:*')
      expect(keys_after_request.size).to eq(1)
      expect(keys_after_request.first).to eq("privacy_tools_check:#{remote_address}")

      value = redis_handler_instance.get(keys_after_request.first)
      expect(value).not_to be_nil
    end
  end

  before do
    allow(RedisHandler).to receive(:new).and_return(redis_handler_instance)
    allow(redis_handler_instance).to receive(:member_of_set?).with('whitelisted_countries',
                                                                   country).and_return(member_result)

    keys = redis_handler_instance.keys('privacy_tools_check:*')
    redis_handler_instance.del(*keys) if keys.any?
  end

  context 'when user does not exist' do
    context 'with rooted_device true' do
      let(:rooted_device) { true }

      it_behaves_like 'expects_user_is_created_with_status', 'banned'

      it_behaves_like 'expects_integrity_log_is_created_with_status', 'banned'
    end

    context 'with rooted_device false' do
      let(:rooted_device) { false }

      context 'when country header is blank' do
        let(:country) { '' }
        let(:member_result) { nil }

        context 'when third_party_api returns one privacy_tool banned' do
          around do |example|
            VCR.use_cassette('check-status/privacy_tool_api_vpn_false_tor_true') do
              example.run
            end
          end

          it_behaves_like 'expects_user_is_created_with_status', 'banned'

          it_behaves_like 'expects_integrity_log_is_created_with_status', 'banned'

          it_behaves_like 'creates_a_cache_key_value_pair'
        end

        context 'when third_party_api returns all privacy_tools not_banned' do
          around do |example|
            VCR.use_cassette('check-status/privacy_tool_api_vpn_false_tor_false') do
              example.run
            end
          end

          it_behaves_like 'expects_user_is_created_with_status', 'not_banned'

          it_behaves_like 'expects_integrity_log_is_created_with_status', 'not_banned'

          it_behaves_like 'creates_a_cache_key_value_pair'
        end
      end

      context 'when country header is whitelisted' do
        let(:country) { 'ES' }
        let(:member_result) { true }

        context 'when third_party_api returns one privacy_tool banned' do
          around do |example|
            VCR.use_cassette('check-status/privacy_tool_api_vpn_false_tor_true', match_requests_on: %i[body uri]) do
              example.run
            end
          end

          it_behaves_like 'expects_user_is_created_with_status', 'banned'

          it_behaves_like 'expects_integrity_log_is_created_with_status', 'banned'

          it_behaves_like 'creates_a_cache_key_value_pair'
        end

        context 'when third_party_api returns two privacy_tools not_banned' do
          around do |example|
            VCR.use_cassette('check-status/privacy_tool_api_vpn_false_tor_false', match_requests_on: %i[body uri]) do
              example.run
            end
          end

          it_behaves_like 'expects_user_is_created_with_status', 'not_banned'

          it_behaves_like 'expects_integrity_log_is_created_with_status', 'not_banned'

          it_behaves_like 'creates_a_cache_key_value_pair'
        end
      end

      context 'when country header is not whitelisted' do
        let(:country) { 'ZZ' }
        let(:member_result) { false }

        it_behaves_like 'expects_user_is_created_with_status', 'banned'

        it_behaves_like 'expects_integrity_log_is_created_with_status', 'banned'
      end
    end
  end

  context 'when user already exists with not_banned ban_status' do
    let!(:user) { create(:user, idfa:, ban_status: 'not_banned') }

    context 'with rooted_device true' do
      let(:rooted_device) { true }

      it_behaves_like 'expects_user_is_updated_with_status', 'banned'

      it_behaves_like 'expects_integrity_log_is_created_with_status', 'banned'
    end

    context 'with rooted_device false' do
      let(:rooted_device) { false }

      context 'when country header is blank' do
        let(:country) { '' }
        let(:member_result) { nil }

        context 'when cache does not exist' do
          context 'when third_party_api returns one privacy_tool banned' do
            around do |example|
              VCR.use_cassette('check-status/privacy_tool_api_vpn_false_tor_true') do
                example.run
              end
            end

            it_behaves_like 'expects_user_is_updated_with_status', 'banned'

            it_behaves_like 'expects_integrity_log_is_created_with_status', 'banned'

            it_behaves_like 'creates_a_cache_key_value_pair'
          end

          context 'when third_party_api returns all privacy_tools not_banned' do
            around do |example|
              VCR.use_cassette('check-status/privacy_tool_api_vpn_false_tor_false') do
                example.run
              end
            end

            it_behaves_like 'expects_user_is_not_updated', 'not_banned'

            it_behaves_like 'expects_integrity_log_is_not_created'

            it_behaves_like 'creates_a_cache_key_value_pair'
          end
        end

        context 'when cache exists' do
          context 'when cache returns one privacy_tool banned' do
            let(:cached_body) do
              {
                security: {
                  vpn: false,
                  tor: true
                }
              }.to_json
            end

            before do
              redis_handler_instance.set("privacy_tools_check:#{ip}", cached_body, expires_in: cache_ttl)
            end

            it_behaves_like 'expects_user_is_updated_with_status', 'banned'

            it_behaves_like 'expects_integrity_log_is_created_with_status', 'banned'

            it_behaves_like 'does_not_create_a_cache_key_value_pair'
          end

          context 'when cache returns all privacy_tools not_banned' do
            let(:cached_body) do
              {
                security: {
                  vpn: false,
                  tor: false
                }
              }.to_json
            end

            before do
              redis_handler_instance.set("privacy_tools_check:#{ip}", cached_body, expires_in: cache_ttl)
            end

            it_behaves_like 'expects_user_is_not_updated', 'not_banned'

            it_behaves_like 'expects_integrity_log_is_not_created'

            it_behaves_like 'does_not_create_a_cache_key_value_pair'
          end
        end
      end

      context 'when country header is whitelisted' do
        let(:country) { 'ES' }
        let(:member_result) { true }

        context 'when cache does not exist' do
          context 'when third_party_api returns one privacy_tool banned' do
            around do |example|
              VCR.use_cassette('check-status/privacy_tool_api_vpn_false_tor_true') do
                example.run
              end
            end

            it_behaves_like 'expects_user_is_updated_with_status', 'banned'

            it_behaves_like 'expects_integrity_log_is_created_with_status', 'banned'

            it_behaves_like 'creates_a_cache_key_value_pair'
          end

          context 'when third_party_api returns all privacy_tools not_banned' do
            around do |example|
              VCR.use_cassette('check-status/privacy_tool_api_vpn_false_tor_false') do
                example.run
              end
            end

            it_behaves_like 'expects_user_is_not_updated', 'not_banned'

            it_behaves_like 'expects_integrity_log_is_not_created'

            it_behaves_like 'creates_a_cache_key_value_pair'
          end
        end

        context 'when cache exists' do
          context 'when cache returns one privacy_tool banned' do
            let(:cached_body) do
              {
                security: {
                  vpn: false,
                  tor: true
                }
              }.to_json
            end

            before do
              redis_handler_instance.set("privacy_tools_check:#{ip}", cached_body, expires_in: cache_ttl)
            end

            it_behaves_like 'expects_user_is_updated_with_status', 'banned'

            it_behaves_like 'expects_integrity_log_is_created_with_status', 'banned'

            it_behaves_like 'does_not_create_a_cache_key_value_pair'
          end

          context 'when cache returns all privacy_tools not_banned' do
            let(:cached_body) do
              {
                security: {
                  vpn: false,
                  tor: false
                }
              }.to_json
            end

            before do
              redis_handler_instance.set("privacy_tools_check:#{ip}", cached_body, expires_in: cache_ttl)
            end

            it_behaves_like 'expects_user_is_not_updated', 'not_banned'

            it_behaves_like 'expects_integrity_log_is_not_created'

            it_behaves_like 'does_not_create_a_cache_key_value_pair'
          end
        end
      end

      context 'when country header is not whitelisted' do
        let(:country) { 'ZZ' }
        let(:member_result) { false }

        it_behaves_like 'expects_user_is_updated_with_status', 'banned'

        it_behaves_like 'expects_integrity_log_is_created_with_status', 'banned'
      end
    end
  end

  context 'when user already exists with banned ban_status' do
    let!(:user) { create(:user, idfa:, ban_status: 'banned') }

    context 'with rooted_device false' do
      let(:rooted_device) { false }

      it_behaves_like 'expects_user_is_not_updated', 'banned'

      it_behaves_like 'expects_integrity_log_is_not_created'
    end

    context 'with rooted_device true' do
      let(:rooted_device) { true }

      it_behaves_like 'expects_user_is_not_updated', 'banned'

      it_behaves_like 'expects_integrity_log_is_not_created'
    end
  end
end
