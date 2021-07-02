# frozen_string_literal: true

class AddForeignKeyAndIndexForUserPendingAlertEscalations < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  RULE_USER_INDEX_NAME = 'index_on_user_pending_escalations_alert'

  def up
    add_index :incident_management_pending_alert_escalations, :user_id, name: RULE_USER_INDEX_NAME
    add_foreign_key(:incident_management_pending_alert_escalations, :users, column: :user_id, on_delete: :nullify)
  end

  def down
    remove_index :incident_management_pending_alert_escalations, :user_id, name: RULE_USER_INDEX_NAME
    remove_foreign_key :incident_management_pending_alert_escalations, column: :user_id
  end
end
