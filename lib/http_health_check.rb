# frozen_string_literal: true

require 'rack'

require_relative 'http_health_check/version'
require_relative 'http_health_check/config/dsl'
require_relative 'http_health_check/probe'
require_relative 'http_health_check/rack_app'
require_relative 'http_health_check/probes'

module HttpHealthCheck
  class Error < StandardError; end

  class ConfigurationError < Error; end

  def self.configure(&block)
    @rack_app = RackApp.configure(&block)
  end

  def self.rack_app
    @rack_app ||= RackApp.configure { |c| add_builtin_probes(c) }
  end

  def self.add_builtin_probes(conf)
    conf.probe '/readiness/sidekiq', Probes::Sidekiq.new if defined?(::Sidekiq)
    conf.probe '/readiness/delayed_job', Probes::DelayedJob.new if defined?(::Delayed::Job)

    conf
  end

  def self.run_server_async(opts)
    Thread.new { run_server(opts) }
  end

  def self.run_server(port:, host: '0.0.0.0', rack_app: nil)
    rack_app ||= ::HttpHealthCheck.rack_app
    app = rack_app.logger.nil? ? rack_app : ::Rack::CommonLogger.new(rack_app, rack_app.logger)

    ::Rack::Handler::WEBrick.run(app,
                                 Host: host,
                                 Port: port,
                                 AccessLog: [],
                                 Logger: rack_app.logger)
  end
end
