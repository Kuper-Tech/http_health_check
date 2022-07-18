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
        @meta = Hash(meta)
        @ok = is_ok
      rescue StandardError => e
        e = ::HttpHealthCheck::ConfigurationError.new(e.message)
        e.set_backtrace(e.backtrace)
        raise e
      end
      attr_reader :meta

      def ok?
        @ok
      end
    end
  end
end
