# frozen_string_literal: true

class AddIndexToAlertManagementAlertsMonitoringTool < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_alert_management_alerts_on_monitoring_tool'

  def up
    add_concurrent_index :alert_management_alerts, [:issue_id, :monitoring_tool], name: INDEX_NAME, where: "(monitoring_tool != 'Cilium')"
  end

  def down
    remove_concurrent_index_by_name :alert_management_alerts, INDEX_NAME
  end
end
