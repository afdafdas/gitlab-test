# frozen_string_literal: true

module Provider
  module ContractSourceHelper
    QA_PACT_BROKER_HOST = "http://localhost:9292/pacts"
    PREFIX_PATHS = {
      rake: "../../../contracts/contracts/project",
      spec: "../contracts/project"
    }.freeze
    SUB_PATH_REGEX = %r{project/(?<file_path>.*?)_helper.rb}.freeze

    class << self
      def contract_location(requester, file_path)
        raise ArgumentError, 'requester must be :rake or :spec' unless [:rake, :spec].include? requester

        relevant_path = file_path.match(SUB_PATH_REGEX)[:file_path].split('/')

        ENV["PACT_BROKER"] ? pact_broker_url(relevant_path) : local_contract_location(requester, relevant_path)
      end

      def pact_broker_url(file_path)
        provider_url = "provider/#{construct_provider_url_path(file_path)}"
        consumer_url = "consumer/#{construct_consumer_url_path(file_path)}"

        "#{QA_PACT_BROKER_HOST}/#{provider_url}/#{consumer_url}/latest"
      end

      def construct_provider_url_path(file_path)
        split_name = file_path[2].split('_')

        split_name[0] = split_name[0].upcase
        split_name.join("%20")
      end

      def construct_consumer_url_path(file_path)
        "#{file_path[0].split('_').map(&:capitalize).join}%23#{file_path[1]}"
      end

      def local_contract_location(requester, file_path)
        contract_path = construct_local_contract_path(file_path)
        prefix_path = requester == :rake ? File.expand_path(PREFIX_PATHS[requester], __dir__) : PREFIX_PATHS[requester]

        "#{prefix_path}#{contract_path}"
      end

      def construct_local_contract_path(file_path)
        contract_file_name = "#{file_path[0].tr('_', '')}##{file_path[1]}-#{file_path[2]}.json"

        "/#{file_path[0]}/#{file_path[1]}/#{contract_file_name}"
      end
    end
  end
end
