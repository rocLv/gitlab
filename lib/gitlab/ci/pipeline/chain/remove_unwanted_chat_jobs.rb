# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class RemoveUnwantedChatJobs < Chain::Base
          def perform!
            raise ArgumentError, 'missing YAML processor result' unless @command.yaml_processor_result

            return unless pipeline.chat? || pipeline.package_push_event?

            if pipeline.chat?
              @command.yaml_processor_result.jobs.select! do |name, _|
                name.to_s == command.chat_data[:command].to_s
              end
            end

            if pipeline.package_push_event?
              @command.yaml_processor_result.jobs.select! do |_, attributes|
                'package_push'.in?(attributes.dig(:only, :refs))
              end
            end
          end

          def break?
            false
          end
        end
      end
    end
  end
end
