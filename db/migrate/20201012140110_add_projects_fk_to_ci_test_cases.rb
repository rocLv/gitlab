# frozen_string_literal: true

class AddProjectsFkToCiTestCases < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_test_cases, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :ci_test_cases, column: :project_id
    end
  end
end
