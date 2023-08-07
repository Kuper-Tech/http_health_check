# frozen_string_literal: true

require 'redis'
require 'redis-client'
module Sidekiq; end
require_relative '../../../lib/http_health_check/probes/sidekiq'

describe HttpHealthCheck::Probes::Sidekiq do
  subject { described_class.new(sidekiq: sidekiq) }
  let(:fake_sidekiq) do
    Class.new do
      def initialize(redis)
        @redis = redis
      end

      def redis
        yield @redis
      end
    end
  end

  let(:sidekiq) { fake_sidekiq.new(redis) }

  shared_context :connected_redis do
    let(:redis_url) { ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/1') }
  end

  shared_context :disconnected_redis do
    let(:redis_url) { 'redis://127.0.0.1:63799/999' }
  end

  shared_examples :positive_probe do
    it 'writes temporary key into redis and returns positive result' do
      result = subject.call(nil)
      expect(result).to be_ok

      expect(redis.call('GET', result.meta[:redis_key]).to_i).to eq(described_class::MAGIC_NUMBER)

      ttl = redis.call('TTL', result.meta[:redis_key]).to_i
      expect(ttl).to be <= described_class::TTL_SEC
      expect(ttl).to be > 0
    end
  end

  shared_examples :negative_probe do
    it 'returns an error' do
      result = subject.call(nil)
      expect(result).not_to be_ok
      expect(result.meta[:error_class].split('::').last).to eq('CannotConnectError')
    end
  end

  context 'with redis' do
    let(:redis) { Redis.new(url: redis_url) }

    context 'when server is available', redis: true do
      include_context :connected_redis

      it_behaves_like :positive_probe
    end

    context 'when server is not available', redis: true do
      include_context :disconnected_redis

      it_behaves_like :negative_probe
    end
  end

  context 'with redis-client' do
    let(:redis) { RedisClient.new(url: redis_url) }

    context 'when server is available', redis: true do
      include_context :connected_redis

      it_behaves_like :positive_probe
    end

    context 'when redis-client is not available', redis: true do
      include_context :disconnected_redis

      it_behaves_like :negative_probe
    end
  end
end
