# frozen_string_literal: true

# See compatibility table at https://www.fastruby.io/blog/ruby/rails/versions/compatibility-table.html

versions_map = {
  '6.0' => %w[2.7],
  '6.1' => %w[2.7 3.0],
  '7.0' => %w[3.1],
  '7.1' => %w[3.2],
  '7.2' => %w[3.3 3.4],
  '8.0' => %w[3.4]
}

current_ruby_version = RUBY_VERSION.split('.').first(2).join('.')

versions_map.each do |rails_version, ruby_versions|
  ruby_versions.each do |ruby_version|
    next if ruby_version != current_ruby_version

    appraise "rails-#{rails_version}" do
      gem 'rails', "~> #{rails_version}.0"
    end
  end
end
