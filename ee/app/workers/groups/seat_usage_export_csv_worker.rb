# frozen_string_literal: true

# Worker for exporting group seat usage.
module Groups
  class SeatUsageExportCsvWorker
    include ApplicationWorker

    data_consistency :delayed
    feature_category :utilization
    sidekiq_options retry: 3

    # group_id - The ID of the group for which to export seat usage.
    # user_id - The ID of user that requested the export.
    def perform(group_id, user_id)
      group = Group.find(group_id)
      return unless group&.root?

      user = User.find(user_id)
      return unless ::Ability.allowed?(user, :admin_group_member, group)

      Groups::SeatUsageExportService.execute(group, user)
    rescue ActiveRecord::RecordNotFound => error
      logger.error("Failed to export CSV (user_id: #{user_id}, group_id: #{group_id}): #{error.message}")
    end
  end
end
