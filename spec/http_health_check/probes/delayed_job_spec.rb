# frozen_string_literal: true

require 'redis'
require_relative '../../../lib/http_health_check/probes/delayed_job'

describe HttpHealthCheck::Probes::DelayedJob do
  subject { described_class.new(delayed_job: delayed_job) }
  let(:delayed_job) { double }
  let(:enqueued_job) { double }

  it 'returns ok-result on success' do
    expect(delayed_job).to receive(:enqueue)
      .with(HttpHealthCheck::Probes::DelayedJob::HealthCheckJob)
      .and_return(enqueued_job)

    expect(enqueued_job).to receive(:destroy!).and_return(true)

    result = subject.call(nil)
    expect(result).to be_ok
  end

  it 'wraps exceptions into error-result' do
    expect(delayed_job).to receive(:enqueue)
      .with(HttpHealthCheck::Probes::DelayedJob::HealthCheckJob)
      .and_raise(RuntimeError, 'boom')

    result = subject.call(nil)
    expect(result).not_to be_ok
    expect(result.meta[:error_class]).to eq('RuntimeError')
    expect(result.meta[:error_message]).to eq('boom')
  end
end
