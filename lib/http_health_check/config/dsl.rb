# frozen_string_literal: true

module HttpHealthCheck
  module Config
    class Dsl
      def initialize
        @routes = {}
      end
      attr_reader :routes, :configured_fallback_app

      def probe(path, handler = nil, &block)
        @routes[path] = block_given? ? block : handler
      end

      def fallback_app(handler = nil, &block)
        @configured_fallback_app = block_given? ? block : handler
      end
    end
  end
end
