# frozen_string_literal: true

module HttpHealthCheck
  module Probes
    class RubyKafka
      Heartbeat = Struct.new(:time, :group, :topic_partitions)
      include ::HttpHealthCheck::Probe

      def initialize(opts = {})
        @heartbeat_event_name = opts.fetch(:heartbeat_event_name, /heartbeat.consumer.kafka/)
        @heartbeat_interval_sec = opts.fetch(:heartbeat_interval_sec, 10)
        @verbose = opts.fetch(:verbose, false)
        @consumer_groups = opts.fetch(:consumer_groups)
                               .each_with_object(Hash.new(0)) { |group, hash| hash[group] += 1 }
        @heartbeats = {}
        @timer = opts.fetch(:timer, Time)

        setup_subscriptions
      end

      def probe(_env)
        now = @timer.now
        failed_heartbeats = select_failed_heartbeats(now)
        return probe_ok groups: meta_from_heartbeats(@heartbeats, now) if failed_heartbeats.empty?

        probe_error failed_groups: meta_from_heartbeats(failed_heartbeats, now)
      end

      private

      def select_failed_heartbeats(now)
        @consumer_groups.each_with_object({}) do |(group, concurrency), hash|
          heartbeats = @heartbeats[group] || {}
          ok_heartbeats_count = heartbeats.count { |_id, hb| hb.time + @heartbeat_interval_sec >= now }
          hash[group] = heartbeats if ok_heartbeats_count < concurrency
        end
      end

      def meta_from_heartbeats(heartbeats_hash, now) # rubocop: disable Metrics/MethodLength, Metrics/AbcSize
        heartbeats_hash.each_with_object({}) do |(group, heartbeats), hash|
          concurrency = @consumer_groups[group]
          if heartbeats.empty?
            hash[group] = { had_heartbeat: false, concurrency: concurrency }
            next
          end

          hash[group] = { had_heartbeat: true, concurrency: concurrency, threads: {} }
          heartbeats.each do |thread_id, heartbeat|
            thread_meta = { seconds_since_last_heartbeat: now - heartbeat.time }
            thread_meta[:topic_partitions] = heartbeat.topic_partitions if @verbose
            hash[group][:threads][thread_id] = thread_meta
          end
        end
      end

      def setup_subscriptions
        ActiveSupport::Notifications.subscribe(@heartbeat_event_name) do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          group = event.payload[:group_id]

          @heartbeats[group] ||= {}
          @heartbeats[group][event.transaction_id] = Heartbeat.new(event.time, group, event.payload[:topic_partitions])
        end
      end
    end
  end
end
