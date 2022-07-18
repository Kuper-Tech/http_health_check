# frozen_string_literal: true

require 'redis'
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

  context 'when redis is available' do
    let(:redis) { Redis.new(url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/1')) }

    it 'writes temporary key into redis and returns positive result' do
      result = subject.call(nil)
      expect(result).to be_ok

      expect(redis.get(result.meta[:redis_key]).to_i).to eq(described_class::MAGIC_NUMBER)

      ttl = redis.ttl(result.meta[:redis_key]).to_i
      expect(ttl).to be <= described_class::TTL_SEC
      expect(ttl).to be > 0
    end
  end

  context 'when redis is not available' do
    let(:redis) { Redis.new(url: 'redis://127.0.0.1:63799/999') }

    it 'returns an error' do
      result = subject.call(nil)
      expect(result).not_to be_ok
      expect(result.meta[:error_class]).to eq('Redis::CannotConnectError')
    end
  end
end
