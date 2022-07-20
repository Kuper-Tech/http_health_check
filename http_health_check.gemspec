# frozen_string_literal: true

require_relative 'lib/http_health_check/version'

Gem::Specification.new do |spec|
  spec.name          = 'http_health_check'
  spec.version       = HttpHealthCheck::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ['SberMarket team']
  spec.email         = ['pochi.73@gmail.com']

  spec.summary       = 'Simple and extensible HTTP health checks server.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/SberMarket-Tech/http_health_check'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org/'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/SberMarket-Tech/http_health_check'
  spec.metadata['changelog_uri'] = 'https://github.com/SberMarket-Tech/http_health_check/blob/main/CHANGELOG.md'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rack', '~> 2.0'
  spec.add_dependency 'webrick'

  spec.add_development_dependency 'activesupport', '~> 5.0'
  spec.add_development_dependency 'dotenv', '~> 2.7.6'
  spec.add_development_dependency 'redis', '~> 4.2.5'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'rubocop', '~> 0.81'
  spec.add_development_dependency 'thor', '>= 0.20'
end
