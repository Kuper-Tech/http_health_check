# frozen_string_literal: true

require 'json'
require 'logger'

module HttpHealthCheck
  class RackApp
    HEADERS = { 'Content-Type' => 'application/json' }.freeze
    DEFAULT_FALLBACK_APP = ->(_env) { [404, HEADERS, ['{"error": "not_found"}']] }.freeze
    LIVENESS_CHECK_APP = ->(_env) { [200, HEADERS, ["{}\n"]] }

    def self.configure
      config = Config::Dsl.new
      yield config

      fallback_app = config.configured_fallback_app || DEFAULT_FALLBACK_APP
      new(config.routes, fallback_app: fallback_app, logger: config.configured_logger)
    end

    def initialize(routes, fallback_app: DEFAULT_FALLBACK_APP, logger: nil)
      @logger = logger || Logger.new(IO::NULL, level: Logger::Severity::UNKNOWN)
      @fallback_app = ensure_callable!(fallback_app)
      @routes = routes.each_with_object('/liveness' => LIVENESS_CHECK_APP) do |(path, handler), acc|
        acc[path.to_s] = ensure_callable!(handler)
      end
    end
    attr_reader :routes, :fallback_app, :logger

    def call(env)
      result = routes.fetch(env[Rack::REQUEST_PATH], fallback_app).call(env)
      return result unless result.is_a?(Probe::Result)

      [result.ok? ? 200 : 500, HEADERS, [result.meta.to_json]]
    end

    private

    def ensure_callable!(obj)
      return obj if obj.respond_to?(:call)

      raise ::HttpHealthCheck::ConfigurationError, 'HTTP handler must be callable'
    end
  end
end
