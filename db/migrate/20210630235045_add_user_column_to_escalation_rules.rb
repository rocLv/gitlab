# frozen_string_literal: true

class AddUserColumnToEscalationRules < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  RULE_USER_INDEX_NAME = 'index_on_user_escalation_rule'

  def up
    add_column :incident_management_escalation_rules, :user_id, :integer, null: true
  end

  def down
    with_lock_retries do
      remove_column :incident_management_escalation_rules, :user_id
    end
  end
end
