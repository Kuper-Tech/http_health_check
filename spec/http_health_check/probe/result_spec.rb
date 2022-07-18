# frozen_string_literal: true

require 'rspec'

describe HttpHealthCheck::Probe::Result do
  it 'handles configuration errors' do
    expect { described_class.ok(42) }
      .to raise_error(HttpHealthCheck::ConfigurationError, "can't convert Integer into Hash")
  end
end
