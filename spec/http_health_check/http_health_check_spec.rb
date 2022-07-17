# frozen_string_literal: true

require 'spec_helper'
require 'net/http'
require 'uri'

describe HttpHealthCheck do
  let(:port) { 51_142 }

  def request(path)
    uri = URI.parse('http://127.0.0.1')
    uri.path = path
    uri.port = port

    Net::HTTP.get_response(uri)
  end

  def wait_server_started(attempts_left = 10)
    Socket.tcp('127.0.0.1', port, connect_timeout: 1) {}
  rescue StandardError
    raise if attempts_left == 0

    sleep(0.005)
    wait_server_started(attempts_left - 1)
  end

  def start_server(opts = {})
    HttpHealthCheck.run_server_async(opts.merge(port: port)).tap { wait_server_started }
  end

  describe '#run_server_async' do
    after { Thread.kill(server) }

    context 'with global configuration' do
      let!(:server) { start_server }

      it 'starts http server' do
        expect(request('/liveness').code).to eq('200')
        expect(request('/foobar').code).to eq('404')
      end
    end

    context 'with custom configuration' do
      let(:rack_app) do
        HttpHealthCheck::RackApp.configure do |c|
          c.probe('/foobar') { |_env| [204, {}, [':)']] }
          c.fallback_app { |_env| [418, {}, ['+_+']] }

          HttpHealthCheck.add_builtin_probes(c)
        end
      end
      let!(:server) { start_server rack_app: rack_app }

      it 'starts http server' do
        expect(request('/liveness').code).to eq('200')
        expect(request('/foobar').code).to eq('204')
        expect(request('/bazqux').code).to eq('418')
      end
    end
  end
end
