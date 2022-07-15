# frozen_string_literal: true

module HttpHealthCheck
  class DelayedJob
    class HealthCheckJob
      def self.perform; end

      def self.queue_name
        'health-check'
      end
    end
  end
end
