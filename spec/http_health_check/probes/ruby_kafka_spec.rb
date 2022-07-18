# frozen_string_literal: true

require 'active_support/notifications'
require_relative '../../../lib/http_health_check/probes/ruby_kafka'

describe HttpHealthCheck::Probes::RubyKafka do
  let(:timer) { double(Time) }
  let(:event_name) { 'fake.heartbeat.consumer.kafka' }
  let(:consumer_groups) { nil }
  let!(:probe) do
    described_class.new(
      consumer_groups: consumer_groups,
      timer: timer,
      heartbeat_event_name: event_name
    )
  end

  def emit_hb_event(group, topic_partitions: nil)
    topic_partitions ||= { 'some_topic' => %w[1 2] }
    ActiveSupport::Notifications.instrument(event_name, group_id: group, topic_partitions: topic_partitions) {}
  end

  context 'with list of consumer groups' do
    let(:group) { 'important-consumer' }
    let(:consumer_groups) { [group] }

    context 'when specified group heartbeat is expired' do
      it 'returns an error' do
        topic_partitions = { 'foo' => %w[1 2], 'bar' => %w[3 4] }
        emit_hb_event(group, topic_partitions: topic_partitions)

        expect(timer).to receive(:now).and_return(Time.now + 15)
        result = probe.call(nil)
        expect(result).not_to be_ok

        meta = result.meta[:failed_groups][group]
        expect(meta[:seconds_since_last_heartbeat]).to be_within(1).of(15)
        expect(meta[:topic_partitions]).to eq(topic_partitions)
        expect(meta[:had_heartbeat]).to eq(true)
      end
    end

    context 'when specified group heartbeat had not been emitted yet' do
      it 'return an error' do
        expect(timer).to receive(:now).and_return(Time.now)

        result = probe.call(nil)
        expect(result).not_to be_ok

        meta = result.meta[:failed_groups][group]
        expect(meta[:had_heartbeat]).to eq(false)
      end
    end

    context 'when it noted specified group heartbeat recently' do
      it 'returns ok' do
        emit_hb_event(group)

        expect(timer).to receive(:now).and_return(Time.now + 5)
        result = probe.call(nil)
        expect(result).to be_ok

        meta = result.meta[:groups][group]
        expect(meta[:seconds_since_last_heartbeat]).to be_within(1).of(5)
        expect(meta[:had_heartbeat]).to eq(true)
      end
    end
  end

  context 'without list of consumer groups' do
    let(:consumer_groups) { nil }

    context 'when no heartbeats were emitted' do
      it 'return ok' do
        expect(timer).to receive(:now).and_return(Time.now)

        result = probe.call(nil)
        expect(result).to be_ok
      end
    end

    context 'when heartbeat is expired' do
      it 'return an error' do
        emit_hb_event('consumer-group')

        expect(timer).to receive(:now).and_return(Time.now + 15)
        result = probe.call(nil)
        expect(result).not_to be_ok

        expect(result.meta[:failed_groups].keys).to eq(['consumer-group'])
      end
    end
  end
end
