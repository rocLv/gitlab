# frozen_string_literal: true

module Ci
  module Minutes
    class UpdateBuildMinutesService < BaseService
      # Calculates consumption and updates the project and namespace statistics(legacy)
      # or ProjectMonthlyUsage and NamespaceMonthlyUsage(not legacy) based on the passed build.
      def execute(build)
        return unless build.shared_runners_minutes_limit_enabled?
        return unless build.complete?
        return unless build.duration&.positive?

        consumption = ::Gitlab::Ci::Minutes::BuildConsumption.new(build, build.duration).amount

        return unless consumption > 0

        # TODO(Issue #335338): Introduce async worker UpdateProjectAndNamespaceUsageWorker
        Ci::Minutes::UpdateProjectAndNamespaceUsageService.new(project, namespace).execute(consumption)

        compare_with_live_consumption(build, consumption)
      end

      private

      def compare_with_live_consumption(build, consumption)
        live_consumption = ::Ci::Minutes::TrackLiveConsumptionService.new(build).live_consumption
        return if live_consumption == 0

        difference = consumption.to_f - live_consumption.to_f
        observe_ci_minutes_difference(difference, plan: namespace.actual_plan_name)
      end

      def namespace
        project.shared_runners_limit_namespace
      end

      def observe_ci_minutes_difference(difference, plan:)
        ::Gitlab::Ci::Pipeline::Metrics
          .gitlab_ci_difference_live_vs_actual_minutes
          .observe({ plan: plan }, difference)
      end
    end
  end
end
