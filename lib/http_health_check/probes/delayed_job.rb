# frozen_string_literal: true

require_relative 'delayed_job/health_check_job'

module HttpHealthCheck
  module Probes
    class DelayedJob
      autoload :HealthCheckJob, 'lib/probes/delayed_job/health_check_job'
      include ::HttpHealthCheck::Probe

      def probe(_env)
        ::Delayed::Job.enqueue(HealthCheckJob).destroy!
        probe_ok
      end
    end
  end
end
