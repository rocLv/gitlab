# frozen_string_literal: true

class Groups::SeatUsageController < Groups::ApplicationController
  before_action :authorize_admin_group_member!
  before_action :verify_namespace_plan_check_enabled

  layout "group_settings"

  feature_category :purchase

  def show
  end

  def export
    return not_found unless Feature.enabled?(:seat_usage_export, group)

    Groups::SeatUsageExportCsvWorker.perform_async(group.id, current_user.id)

    message = _('Your CSV export has started. It will be emailed to %{email} when complete.') % { email: current_user.notification_email }
    redirect_to(group_seat_usage_path, notice: message)
  end
end
