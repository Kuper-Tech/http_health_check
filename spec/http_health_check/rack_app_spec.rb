# frozen_string_literal: true

require 'spec_helper'

describe HttpHealthCheck::RackApp do
  describe '.configure' do
    it 'provides DSL for app configuration' do
      app = described_class.configure do |c|
        c.probe '/test', (proc { [418, {}, ["I'm a teapot"]] })
        c.fallback_app do |_env|
          [999, {}, [':(']]
        end
      end

      expect(app.routes['/test'].call(:env).first).to eq(418)
      expect(app.fallback_app.call(:env).first).to eq(999)
    end

    it 'uses default fallback app if none given' do
      app = described_class.configure {}
      expect(app.fallback_app).to eq(described_class::DEFAULT_FALLBACK_APP)
    end

    it 'validates handler is callable' do
      expect do
        described_class.configure do |c|
          c.probe 'foo', 'bar'
        end
      end.to raise_error(HttpHealthCheck::ConfigurationError)
    end
  end

  describe 'call' do
    let(:rack_app) do
      described_class.configure do |c|
        c.probe '/foo' do |_env|
          HttpHealthCheck::Probe::Result.ok(foo: 42)
        end

        c.probe('/bar') { |_env| [200, {}, ['ok']] }

        c.fallback_app { [404, {}, [':(']] }
      end
    end

    context 'when it returns a result struct' do
      it 'converts it into rack response' do
        result = rack_app.call('REQUEST_PATH' => '/foo')
        expect(result).to eq([200, described_class::HEADERS, ['{"foo":42}']])
      end
    end

    context 'when path matches route' do
      it 'calls an app' do
        result = rack_app.call('REQUEST_PATH' => '/bar')
        expect(result).to eq([200, {}, ['ok']])
      end
    end

    context 'when path does not match any route' do
      it 'calls fallback handler' do
        result = rack_app.call('REQUEST_PATH' => '/unknown')
        expect(result).to eq([404, {}, [':(']])
      end
    end
  end
end
