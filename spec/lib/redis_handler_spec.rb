# frozen_string_literal: true

describe RedisHandler do
  let(:redis) { Redis.new }
  let(:handler) { described_class.new(redis_client: redis) }

  let(:test_key) { 'test:key' }
  let(:test_value) { 'some value' }

  before do
    redis.flushdb
  end

  describe '#set and #get' do
    context 'without expires_in' do
      before do
        handler.set(test_key, test_value)
      end

      it 'sets and retrieves a value without expiration' do
        expect(handler.get(test_key)).to eq(test_value)
      end
    end

    context 'with expires_in' do
      before do
        handler.set(test_key, test_value, expires_in: 1)
      end

      it 'removes the key/value pair after the expires_in' do
        expect(handler.get(test_key)).to eq(test_value)
        sleep 2
        expect(handler.get(test_key)).to be_nil
      end
    end
  end

  describe '#keys' do
    before do
      handler.set('test:1', 'val1')
      handler.set('test:2', 'val2')
    end

    it 'returns matching keys' do
      expect(handler.keys('test:*')).to match_array(%w[test:1 test:2])
    end
  end

  describe '#member_of_set?' do
    before do
      redis.sadd('myset', 'member1')
    end

    context 'with value is in the set' do
      let(:value) { 'member1' }

      it 'returns true' do
        expect(handler.member_of_set?('myset', value)).to be true
      end
    end

    context 'with value is not in the set' do
      let(:value) { 'missing' }

      it 'returns false' do
        expect(handler.member_of_set?('myset', 'missing')).to be false
      end
    end
  end

  describe '#del' do
    before do
      handler.set('to_delete', 'value')
    end

    it 'deletes keys' do
      expect(handler.get('to_delete')).to eq('value')
      handler.del('to_delete')
      expect(handler.get('to_delete')).to be_nil
    end
  end
end
