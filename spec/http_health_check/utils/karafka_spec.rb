# frozen_string_literal: true

require 'ostruct'

require_relative '../../../lib/http_health_check/utils/karafka'

describe HttpHealthCheck::Utils::Karafka do
  describe '.consumer_groups' do
    let(:karafka_app) do
      OpenStruct.new(
        consumer_groups: %w[foo bar baz].map { |cg| OpenStruct.new(id: "foo_app_#{cg}") },
        config: OpenStruct.new(client_id: 'foo-app')
      )
    end

    let(:program_name) { '/bin/karafka' }
    let(:result) do
      described_class.consumer_groups(karafka_app, argv: argv, program_name: program_name)
    end

    context 'when script executed with --consumer_groups option' do
      let(:argv) { ['server', '--foo', 'bar', '--consumer-groups', 'bar baz'] }

      it 'returns CLI-selected consumer groups' do
        expect(result).to eq(%w[foo_app_bar foo_app_baz])
      end
    end

    context 'when script executed with --g shortcut option' do
      let(:argv) { ['server', '-g', 'foo baz'] }

      it 'returns CLI-selected consumer groups' do
        expect(result).to eq(%w[foo_app_foo foo_app_baz])
      end
    end

    context 'when script executed without consumer group opts' do
      let(:argv) { ['server'] }

      it 'returns all karafka app\'s groups' do
        expect(result).to eq(%w[foo_app_foo foo_app_bar foo_app_baz])
      end
    end

    context 'when unknown consumer group given as cli arg' do
      let(:argv) { ['server', '-g', 'foo xxx'] }

      it 'filters it out' do
        expect(result).to eq(%w[foo_app_foo])
      end
    end
  end
end
