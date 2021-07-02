# frozen_string_literal: true

class RemoveNullConstraintFromPendingEscalationsAlert < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    change_column_null(:incident_management_pending_alert_escalations, :schedule_id, true)
  end

  def down
    # no-op
  end
end
