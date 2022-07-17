# frozen_string_literal: true

module HttpHealthCheck
  module Probes
    class DelayedJob
      class HealthCheckJob
        def self.perform; end

        def self.queue_name
          'health-check'
        end
      end
      include ::HttpHealthCheck::Probe

      def initialize(delayed_job: ::Delayed::Job)
        @delayed_job = delayed_job
      end

      def probe(_env)
        @delayed_job.enqueue(HealthCheckJob).destroy!
        probe_ok
      end
    end
  end
end
