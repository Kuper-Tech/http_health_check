# frozen_string_literal: true

module HttpHealthCheck
  class RackApp
    HEADERS = { 'Content-Type' => 'application/json' }.freeze
    DEFAULT_FALLBACK_APP = ->(_env) { [404, HEADERS, ['{"error": "not_found"}']] }.freeze
    LIVENESS_CHECK_APP = ->(_env) { [200, HEADERS, ["{}\n"]] }

    def initialize(routes, fallback_app: DEFAULT_FALLBACK_APP)
      @fallback_app = ensure_callable!(fallback_app)
      @routes = routes.reduce({ '/liveness' => LIVENESS_CHECK_APP }) do |acc, (path, handler)|
        acc[path.to_s] = ensure_callable!(handler)
      end
    end

    def call(env)
      result = @routes.fetch(env['REQUEST_PATH'], @fallback_app).call(env)
      return result unless result.is_a?(Probe::Result)

      [result.ok? ? 200 : 500, HEADERS, result.meta.to_json]
    end

    private

    def ensure_callable!(obj)
      return obj if obj.respond_to?(:call)

      raise ::HttpHealthCheck::ConfigurationError, 'HTTP handler must be callable'
    end
  end
end
