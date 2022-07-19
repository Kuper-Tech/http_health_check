# frozen_string_literal: true

module HttpHealthCheck
  module Probes
    class RubyKafka
      Heartbeat = Struct.new(:time, :group, :topic_partitions)
      include ::HttpHealthCheck::Probe

      def initialize(opts = {})
        @heartbeat_event_name = opts.fetch(:heartbeat_event_name, /heartbeat.consumer.kafka/)
        @heartbeat_interval_sec = opts.fetch(:heartbeat_interval_sec, 10)
        @consumer_groups = opts.fetch(:consumer_groups, nil)
        @heartbeats = {}
        @timer = opts.fetch(:timer, Time)

        setup_subscriptions
      end

      def probe(_env)
        now = @timer.now
        failed_heartbeats = select_failed_heartbeats(@consumer_groups || @heartbeats.keys, now)
        return probe_ok groups: meta_from_heartbeats(@heartbeats, now) if failed_heartbeats.empty?

        probe_error failed_groups: meta_from_heartbeats(failed_heartbeats, now)
      end

      private

      def select_failed_heartbeats(consumer_groups, now)
        consumer_groups.each_with_object({}) do |group, hash|
          heartbeat = @heartbeats[group]
          hash[group] = heartbeat if heartbeat.nil? || heartbeat.time + @heartbeat_interval_sec < now
        end
      end

      def meta_from_heartbeats(heartbeats, now) # rubocop: disable Metrics/MethodLength
        heartbeats.each_with_object({}) do |(group, heartbeat), hash|
          if heartbeat.nil?
            hash[group] = { had_heartbeat: false }
            next
          end

          hash[group] = {
            had_heartbeat: true,
            seconds_since_last_heartbeat: now - heartbeat.time,
            topic_partitions: heartbeat.topic_partitions
          }
        end
      end

      def setup_subscriptions
        ActiveSupport::Notifications.subscribe(@heartbeat_event_name) do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          group = event.payload[:group_id]

          @heartbeats[group] = Heartbeat.new(event.time, group, event.payload[:topic_partitions])
        end
      end
    end
  end
end
