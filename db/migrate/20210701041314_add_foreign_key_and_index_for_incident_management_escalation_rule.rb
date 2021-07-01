# frozen_string_literal: true

class AddForeignKeyAndIndexForIncidentManagementEscalationRule < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  RULE_USER_INDEX_NAME = 'index_on_user_escalation_rule'

  def up
    add_concurrent_index :incident_management_escalation_rules, :user_id, name: RULE_USER_INDEX_NAME
    add_concurrent_foreign_key(:incident_management_escalation_rules, :users, column: :user_id, on_delete: :nullify)
  end

  def down
    remove_concurrent_index :incident_management_escalation_rules, :user_id, name: RULE_USER_INDEX_NAME
    remove_foreign_key :incident_management_escalation_rules, column: :user_id
  end
end
