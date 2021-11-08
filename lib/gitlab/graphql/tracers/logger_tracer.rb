# frozen_string_literal: true

module Gitlab
  module Graphql
    module Tracers
      # This tracer writes logs for certain trace events.
      # It reads duration metadata written by TimerTracer.
      class LoggerTracer
        def self.use(schema)
          schema.tracer(self.new)
        end

        def trace(key, data)
          result = yield

          case key
          when "execute_query"
            log_execute_query(**data)
          when "execute_field"
            log_execute_field(**data)
          end

          result
        end

        private

        def log_execute_field(context: nil, duration_s: 0)
          query = context.query
          field = context.field

          max_duration = query.context[:gl_max_field_duration] || 0

          if duration_s > max_duration
            query.context[:gl_max_field_duration] = duration_s
            query.context[:gl_max_field_path] = context.path
            query.context[:gl_max_field_type] = field.type.to_s
          end
        end

        def log_execute_query(query: nil, duration_s: 0)
          # execute_query should always have :query, but we're just being defensive
          return unless query

          analysis_info = query.context[:gl_analysis]&.transform_keys { |key| "query_analysis.#{key}" }
          info = {
            trace_type: 'execute_query',
            query_fingerprint: query.fingerprint,
            duration_s: duration_s,
            operation_name: query.operation_name,
            operation_fingerprint: query.operation_fingerprint,
            is_mutation: query.mutation?,
            variables: clean_variables(query.provided_variables),
            query_string: query.query_string,
            'max_field.duration': query.context[:gl_max_field_duration],
            'max_field.path': query.context[:gl_max_field_path],
            'max_field.type': query.context[:gl_max_field_type],
          }

          info.merge!(::Gitlab::ApplicationContext.current)
          info.merge!(analysis_info) if analysis_info

          ::Gitlab::GraphqlLogger.info(info)
        end

        def clean_variables(variables)
          filtered = ActiveSupport::ParameterFilter
            .new(::Rails.application.config.filter_parameters)
            .filter(variables)

          filtered&.to_s
        end
      end
    end
  end
end
