# frozen_string_literal: true

require_relative 'probe/result'

module HttpHealthCheck
  module Probe
    def call(env)
      with_error_handler { probe(env) }
    end

    def meta
      {}
    end

    def probe_ok(extra_meta = {})
      Result.ok(meta.merge(extra_meta))
    end

    def probe_error(extra_meta = {})
      Result.error(meta.merge(extra_meta))
    end

    def with_error_handler
      yield
    rescue StandardError => e
      probe_error(error_class: e.class.name, error_message: e.message)
    end
  end
end
