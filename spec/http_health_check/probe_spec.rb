# frozen_string_literal: true

require 'spec_helper'

describe HttpHealthCheck::Probe do
  subject(:probe) { probe_class.new(probe_action, probe_meta) }

  let(:probe_class) do
    Class.new do
      include HttpHealthCheck::Probe

      def initialize(action, meta)
        @action = action
        @meta = meta
      end
      attr_reader :meta

      def probe(env)
        @action.call(env)
        probe_ok probe: :ok
      end
    end
  end

  let(:probe_meta) { {} }
  let(:probe_action) { ->(_env) { :ok } }

  context 'when probe raises an exception' do
    let(:probe_action) { ->(_env) { raise StandardError, 'boom' } }

    context 'without meta' do
      it 'returns result with details' do
        result = probe.call(:fake)
        expect(result).to be_an_instance_of(HttpHealthCheck::Probe::Result)
        expect(result).not_to be_ok
        expect(result.meta).to eq(error_class: 'StandardError', error_message: 'boom')
      end
    end

    context 'with meta' do
      let(:probe_meta) { { foo: :bar } }

      it 'includes meta into result' do
        result = probe.call(:fake)
        expect(result.meta).to eq(foo: :bar, error_class: 'StandardError', error_message: 'boom')
      end
    end
  end

  context 'when probe returns ok' do
    let(:probe_meta) { { foo: :bar } }

    it 'wraps it into result struct including meta' do
      result = probe.call(:fake)
      expect(result).to be_ok
      expect(result.meta).to eq(foo: :bar, probe: :ok)
    end
  end
end
