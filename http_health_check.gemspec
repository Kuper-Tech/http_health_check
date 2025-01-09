# frozen_string_literal: true

require_relative 'lib/http_health_check/version'

Gem::Specification.new do |spec|
  spec.name          = 'http_health_check'
  spec.version       = HttpHealthCheck::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ['Kuper Ruby Platform Team']

  spec.summary       = 'Simple and extensible HTTP health checks server.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/Kuper-Tech/http_health_check'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  spec.metadata['allowed_push_host'] = ENV.fetch('NEXUS_URL', 'https://rubygems.org')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rack', '~> 2.0'
  spec.add_dependency 'webrick'

  spec.add_development_dependency 'activesupport', '>= 6.0'
  spec.add_development_dependency 'appraisal', '>= 2.4'
  spec.add_development_dependency 'bundler', '>= 2.3'
  spec.add_development_dependency 'combustion', '>= 1.3'
  spec.add_development_dependency 'dotenv', '~> 2.7.6'
  spec.add_development_dependency 'rake', '>= 13.0'
  spec.add_development_dependency 'redis'
  spec.add_development_dependency 'redis-client'
  spec.add_development_dependency 'rspec', '>= 3.0'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rubocop', '~> 0.81'
  spec.add_development_dependency 'thor', '>= 0.20'
end
