# frozen_string_literal: true

module HttpHealthCheck
  module Probe
    class Result
      def self.ok(meta)
        new(true, meta)
      end

      def self.error(meta)
        new(false, meta)
      end

      def initialize(is_ok, meta)
        unless meta.is_a?(Hash)
          raise ::HttpHealthCheck::ConfigurationError, "Probe result meta must be a Hash, got #{meta.inspect}"
        end

        @ok = is_ok
        @meta = meta
      end
      attr_reader :meta

      def ok?
        @ok
      end
    end
  end
end
