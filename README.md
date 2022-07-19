# HttpHealthCheck

[![Gem Version](https://badge.fury.io/rb/http_health_check.svg)](https://badge.fury.io/rb/http_health_check)

HttpHealthCheck is a tiny framework for building health check for your application components. It provides a set of built-in checkers (a.k.a. probes) and utilities for building your own.

HttpHealthCheck is built with kubernetes health probes in mind, but it can be used with http health checker.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'http_health_check', '~> 0.2.1'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install http_health_check

## Usage

### Sidekiq

Sidekiq health check is available at `/readiness/sidekiq`.

```ruby
# ./config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  HttpHealthCheck.run_server_async(port: 5555)
end
```

### Delayed Job

DelayedJob health check is available at `/readiness/delayed_job`.

```ruby
# ./script/delayed_job
module Delayed::AfterFork
  def after_fork
    HttpHealthCheck.run_server_async(port: 5555)
    super
  end
end
```

### Karafka ~> 1.4

Ruby-kafka probe is disabled by default as it requires app-specific configuration to work properly. Example usage with karafka framework:

```ruby
# ./karafka.rb

class KarafkaApp < Karafka::App
  # ...
  # karafka app configuration
  # ...
end

KarafkaApp.boot!

HttpHealthCheck.run_server_async(
  port: 5555,
  rack_app: HttpHealthCheck::RackApp.configure do |c|
    c.probe '/readiness/karafka', HttpHealthCheck::Probes::RubyKafka.new(
      consumer_groups: KarafkaApp.consumer_groups.map(&:id),
      # default heartbeat interval is 3 seconds, but we want to give it
      # an ability to skip a few before failing the probe
      heartbeat_interval_sec: 10
    )
  end
)
```

Ruby kafka probe supports multi-threaded setups, i.e. if you are using karafka and you define multiple blocks with the same consumer group like

```ruby
class KarafkaApp < Karafka::App
  consumer_groups.draw do
    consumer_group 'foo' do
      # ...
    end
  end

  consumer_groups.draw do
    consumer_group 'foo' do
      # ...
    end
  end
end

KarafkaApp.consumer_groups.map(&:id)
# => ['foo', 'foo']
```

ruby-kafka probe will count heartbeats from multiple threads.

### Kubernetes deployment example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sidekiq
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sidekiq
  template:
    metadata:
      labels:
        app: sidekiq
    spec:
      containers:
        - name: sidekiq
          image: my-app:latest
          livenessProbe:
            httpGet:
              path: /liveness
              port: 5555
              scheme: HTTP
          readinessProbe:
            httpGet:
              path: /readiness/sidekiq
              port: 5555
              scheme: HTTP
```

### Changing global configuration

```ruby
HttpHealthCheck.configure do |c|
  # add probe with any callable class
  c.probe '/health/my_service', MyProbe.new

  # or with block
  c.probe '/health/fake' do |_env|
    [200, {}, ['OK']]
  end

  # optionally add built-in probes
  HttpHealthCheck.add_builtin_probes(c)

  # optionally override fallback (route not found) handler
  c.fallback_handler do |env|
    [404, {}, ['not found :(']]
  end

  # configure requests logger. Disabled by default
  c.logger Rails.logger
end
```

### Running server with custom rack app

```ruby
rack_app = HttpHealthCheck::RackApp.configure do |c|
  c.probe '/health/my_service', MyProbe.new
end
HttpHealthCheck.run_server_async(port: 5555, rack_app: rack_app)
```

### Writing your own probes

Probes are built around [HttpHealthCheck::Probe](./lib/http_health_check/probe.rb) mixin. Every probe defines **probe** method which receives [rack env](https://www.rubydoc.info/gems/rack/Rack/Request/Env)
and should return [HttpHealthCheck::Probe::Result](./lib/http_health_check/probe/result.rb) or rack-compatible response (status-headers-body tuple).
Probe-mixin provides convenience methods `probe_ok` and `probe_error` for creating [HttpHealthCheck::Probe::Result](./lib/http_health_check/probe/result.rb) instance. Both of them accept optional metadata hash that will be added to the response body.
Any exception (StandardError) will be captured and converted into error-result.

```ruby
class MyProbe
  include HttpHealthCheck::Probe

  def probe(_env)
    status = MyService.status
    return probe_ok if status == :ok

    probe_error status: status
  end
end
```

```ruby
HttpHealthCheck.configure do |config|
  config.probe '/readiness/my_service', MyProbe.new
end
```

### Built-in probes

#### [Sidekiq](./lib/http_health_check/probes/sidekiq.rb)

Sidekiq probe ensures that sidekiq is ready by checking redis is available and writable. It uses sidekiq's redis connection pool to avoid spinning up extra connections.
Be aware that this approach does not cover issues with sidekiq being stuck processing slow/endless jobs. Such cases are nearly impossible to cover without false-positive alerts.

```ruby
HttpHealthCheck.configure do |config|
  config.probe '/readiness/delayed_job', HttpHealthCheck::Probes::Sidekiq.new
end
```

#### [DelayedJob](./lib/http_health_check/probes/delayed_job.rb) (active record)

Delayed Job probe is intended to work with [active record backend](https://github.com/collectiveidea/delayed_job_active_record).
It checks DelayedJob is healthy by enqueuing an empty job which will be deleted right after insertion. This allows us to be sure that the underlying database is connectable and writable.
Be aware that by enqueuing a new job with every health check, we are incrementing the primary key sequence.

```ruby
HttpHealthCheck.configure do |config|
  config.probe '/readiness/delayed_job', HttpHealthCheck::Probes::DelayedJob.new
end
```

#### [ruby-kafka](./lib/http_health_check/probes/ruby_kafka.rb)

ruby-kafka probe is expected to be configured with consumer groups list. It subscribes to ruby-kafka's `heartbeat.consumer.kafka` ActiveSupport notification and tracks heartbeats for every given consumer group.
It expects a heartbeat every `:heartbeat_interval_sec` (10 seconds by default).

```ruby
heartbeat_app = HttpHealthCheck::RackApp.configure do |c|
  c.probe '/readiness/kafka', HttpHealthCheck::Probes::Karafka.new(
    consumer_groups: ['consumer-one', 'consumer-two'],
    heartbeat_interval_sec: 42
  )
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.
Some specs require redis to be run. You can use your own installation or start one via docker-compose.

```shell
docker-compose up redis
```

## Deployment

1. Update changelog and git add it
2.

```sh
bump2version patch --allow-dirty
```

3. git push && git push --tags
4. gem build
5. gem push http_health_check-x.x.x.gem
