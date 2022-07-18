# frozen_string_literal: true

require 'spec_helper'
require 'net/http'
require 'uri'

describe HttpHealthCheck do
  let(:port) { 51_142 }

  def request(path_with_query)
    uri = URI.parse("http://127.0.0.1/#{path_with_query}")
    uri.port = port

    Net::HTTP.get_response(uri)
  end

  def wait_server_started(attempts_left = 25)
    Socket.tcp('127.0.0.1', port) {}
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
      class MyCustomProbe
        include HttpHealthCheck::Probe

        def probe(env)
          if env[Rack::QUERY_STRING].include?('fail')
            probe_error query: env[Rack::QUERY_STRING]
          elsif env[Rack::QUERY_STRING].include?('raise')
            raise 'boom'
          else
            probe_ok ok: true
          end
        end

        def meta
          { foo: :bar }
        end
      end

      let(:rack_app) do
        HttpHealthCheck::RackApp.configure do |c|
          c.probe('/foobar') { |_env| [204, {}, [':)']] }
          c.probe('/custom', MyCustomProbe.new)
          c.fallback_app { |_env| [418, {}, ['+_+']] }

          HttpHealthCheck.add_builtin_probes(c)
        end
      end
      let!(:server) { start_server rack_app: rack_app }

      it 'starts http server' do
        expect(request('/liveness').code).to eq('200')
        expect(request('/foobar').code).to eq('204')
        expect(request('/bazqux').code).to eq('418')

        resp_custom_ex = request('/custom?raise=true')
        expect(resp_custom_ex.code).to eq('500')
        expect(JSON.parse(resp_custom_ex.body)).to eq(
          'foo' => 'bar',
          'error_class' => 'RuntimeError',
          'error_message' => 'boom'
        )

        resp_custom_err = request('/custom?fail=true')
        expect(resp_custom_err.code).to eq('500')
        expect(JSON.parse(resp_custom_err.body)).to eq('foo' => 'bar', 'query' => 'fail=true')

        resp_custom_ok = request('/custom')
        expect(resp_custom_ok.code).to eq('200')
        expect(JSON.parse(resp_custom_ok.body)).to eq('foo' => 'bar', 'ok' => true)
      end
    end

    context 'with configured logger' do
      let(:io) { StringIO.new }
      let(:logger) { Logger.new(io, level: Logger::Severity::INFO) }

      let(:rack_app) do
        HttpHealthCheck::RackApp.configure do |c|
          HttpHealthCheck.add_builtin_probes(c)
          c.logger(logger)
        end
      end
      let!(:server) { start_server rack_app: rack_app }

      it 'logs server start and requests' do
        expect(request('/liveness').code).to eq('200')
        io.rewind
        logs = io.read

        expect(logs).to include('WEBrick::HTTPServer#start')
        expect(logs).to include('GET /liveness HTTP/1.1')
      end
    end
  end
end
