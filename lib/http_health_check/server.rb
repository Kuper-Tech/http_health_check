# frozen_string_literal: true

module HttpHealthCheck
  module Server
    def self.run_async(opts)
      Thread.new { run(opts) }
    end

    def self.run(port:, host: '0.0.0.0', rack_app: nil)
      rack_app ||= ::HttpHealthCheck.rack_app
      ::Rack::Handler::WEBrick.run(rack_app, Host: host, Port: port, AccessLog: [])
    end
  end
end
