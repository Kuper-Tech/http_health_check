# frozen_string_literal: true

require_relative 'probes/sidekiq' if defined?(::Sidekiq)
require_relative 'probes/delayed_job' if defined?(::Delayed::Job)

module HttpHealthCheck
  module Probes; end
end
