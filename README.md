# HttpHealthCheck

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'http_health_check', '~> 0.1.1'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install http_health_check

## Usage

### Sidekiq

```ruby
# ./config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  HttpHealthCheck.run_server_async(port: 5555)
end
```

### Delayed Job

```ruby
# ./script/delayed_job
module Delayed::AfterFork
  def after_fork
    HttpHealthCheck.run_server_async(port: 5555)
    super
  end
end
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

  # optionally add builtin probes
  HttpHealthCheck.add_builtin_probes(c)

  # optionally override fallback (route not found) handler
  c.fallback_handler do |env|
    [404, {}, ['not found :(']]
  end
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
Probe-mixin provides convenience methods `probe_ok` and `probe_error` for creating [HttpHealthCheck::Probe::Result](./lib/http_health_check/probe/result.rb) instance. Both of them accept optional metadata hash that will be added to response body.
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

### Builtin probes

#### [Sidekiq](./lib/http_health_check/probes/sidekiq.rb)

Sidekiq probe ensures that sidekiq is ready by checking redis is available and writable. It uses sidekiq's redis connection pool to avoid spinning up extra connections.
Be aware, that this approach does not cover issues with sidekiq being stuck processing slow/endless jobs. Such cases are nearly impossible to cover without false-positive alerts.

```ruby
HttpHealthCheck.configure do |config|
  config.probe '/readiness/delayed_job', HttpHealthCheck::Probes::Sidekiq.new
end
```

#### [DelayedJob](./lib/http_health_check/probes/delayed_job.rb) (active record)

Delayed Job probe is intended to work with [active record backend](https://github.com/collectiveidea/delayed_job_active_record).
It checks DelayedJob is healthy by enqueuing an empty job which will be deleted right after insertion. This allows us to be sure that underlying database is connectable and writable.
Be aware, that by enqueuing a new job with every health check we are incrementing primary key sequence.

```ruby
HttpHealthCheck.configure do |config|
  config.probe '/readiness/delayed_job', HttpHealthCheck::Probes::DelayedJob.new
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.
Some specs require redis to be run. You can use your own installation or start one via docker-compose.

```shell
docker-compose up redis
```

## Deployment

Every new (git) tag will be built and deployed automatically via gitlab CI pipeline. We recommend using [bump2version](https://github.com/c4urself/bump2version) to tag new releases.

1. Update changelog and git add it
2.
```sh
bump2version patch --allow-dirty
```
3. git push && git push --tags
