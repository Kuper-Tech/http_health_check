# frozen_string_literal: true

require 'rack'

require_relative 'http_health_check/version'
require_relative 'http_health_check/probe'
require_relative 'http_health_check/rack_app'
require_relative 'http_health_check/server'
require_relative 'http_health_check/probes'

module HttpHealthCheck
  class Error < StandardError; end

  class ConfigurationError < Error; end

  def self.configure(routes)
    @rack_app = RackApp.new(routes)
  end

  def self.rack_app
    @rack_app ||= init_default_rack_app
  end

  def self.init_default_rack_app
    routes = {}
    routes['readiness/sidekiq'] = Probes::Sidekiq if defined?(::Sidekiq)
    routes['readiness/delayed_job'] = Probes::DelayedJob if defined?(::Delayed::Job)

    RackApp.new(routes)
  end
end
