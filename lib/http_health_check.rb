# frozen_string_literal: true

require 'rack'

require_relative 'http_health_check/version'
require_relative 'http_health_check/config/dsl'
require_relative 'http_health_check/probe'
require_relative 'http_health_check/rack_app'
require_relative 'http_health_check/server'
require_relative 'http_health_check/probes'

module HttpHealthCheck
  class Error < StandardError; end

  class ConfigurationError < Error; end

  def self.configure(&block)
    @rack_app = RackApp.configure(&block)
  end

  def self.rack_app
    @rack_app ||= RackApp.configure do |c|
      c.probe '/readiness/sidekiq', Probes::Sidekiq if defined?(::Sidekiq)
      c.probe '/readiness/delayed_job', Probes::DelayedJob if defined?(::Delayed::Job)
    end
  end
end
