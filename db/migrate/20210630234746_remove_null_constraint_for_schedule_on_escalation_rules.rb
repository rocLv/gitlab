# frozen_string_literal: true

class RemoveNullConstraintForScheduleOnEscalationRules < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    change_column_null(:incident_management_escalation_rules, :oncall_schedule_id, true)
  end

  def down
    # no-op
  end
end
