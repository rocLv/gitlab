# frozen_string_literal: true

class AddMilestoneIdToReleases < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  TABLE_NAME = :releases
  RELATION_NAME = :milestones
  FK_NAME = :milestone_id
  INDEX_NAME = "index_releases_on_#{FK_NAME}"

  disable_ddl_transaction!

  def up
    unless column_exists?(TABLE_NAME, FK_NAME)
      with_lock_retries do
        add_column TABLE_NAME, FK_NAME, :bigint
      end
    end

    add_concurrent_index TABLE_NAME, FK_NAME, name: INDEX_NAME
    add_concurrent_foreign_key TABLE_NAME, RELATION_NAME, column: FK_NAME, on_delete: :nullify
  end

  def down
    remove_foreign_key_if_exists TABLE_NAME, RELATION_NAME
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME

    with_lock_retries do
      remove_column TABLE_NAME, FK_NAME
    end
  end
end
