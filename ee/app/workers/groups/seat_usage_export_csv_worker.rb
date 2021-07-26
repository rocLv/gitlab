# frozen_string_literal: true

# Worker for updating group statistics.
module Groups
  class SeatUsageExportCsvWorker
    include ApplicationWorker

    # data_consistency :always
    #
    # sidekiq_options retry: 3
    #
    # feature_category :source_code_management
    # tags :exclude_from_kubernetes
    # idempotent!
    # loggable_arguments 0, 1
    #
    # # group_id - The ID of the group for which to flush the cache.
    # # statistics - An Array containing columns from NamespaceStatistics to
    # #              refresh, if empty all columns will be refreshed
    #
    # feature_category :issue_tracking
    # worker_resource_boundary :cpu
    # loggable_arguments 2

    def perform(group_id, requester_id)
      # group = Group.find_by_id(group_id)
      #
      # return unless group

      # Groups::UpdateStatisticsService.new(group, statistics: statistics).execute
    end
  end
end
