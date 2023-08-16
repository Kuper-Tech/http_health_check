# frozen_string_literal: true

require 'thor'

module HttpHealthCheck
  module Utils
    module Karafka
      # returns a list of consumer groups configured for current process
      #
      # @param karafka_app descendant of Karafka::App
      def self.consumer_groups(karafka_app, program_name: $PROGRAM_NAME, argv: ARGV) # rubocop:disable Metrics/AbcSize
        all_groups = karafka_app.consumer_groups.map(&:id)
        client_id_prefix = "#{karafka_app.config.client_id.gsub('-', '_')}_"

        return all_groups if program_name.split('/').last != 'karafka'
        return all_groups if argv[0] != 'server'

        parsed_option = Thor::Options.new(
          consumer_groups: Thor::Option.new(:consumer_groups, type: :array, default: nil, aliases: :g)
        ).parse(argv).fetch('consumer_groups', []).first.to_s
        return all_groups if parsed_option == ''

        groups_from_option = parsed_option.split(' ').map { |g| client_id_prefix + g } & all_groups
        groups_from_option.empty? ? all_groups : groups_from_option
      end
    end
  end
end
