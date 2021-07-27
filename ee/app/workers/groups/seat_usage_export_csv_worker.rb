# frozen_string_literal: true

# Worker for updating group statistics.
module Groups
  class SeatUsageExportCsvWorker
    include ApplicationWorker

    data_consistency :delayed
    feature_category :utilization
    sidekiq_options retry: 3

    # group_id - The ID of the group for which to export seat usage.
    # user_id - The ID of user that requested the export.
    def perform(group_id, user_id)
      group = Group.find_by_id(group_id)
      return unless group

      user = User.find_by_id(user_id)
      return unless user

      # Groups::UpdateStatisticsService.new(group, statistics: statistics).execute
    end
  end
end
