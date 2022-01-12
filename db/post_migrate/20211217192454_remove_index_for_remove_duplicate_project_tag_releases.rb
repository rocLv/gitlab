# frozen_string_literal: true

class RemoveIndexForRemoveDuplicateProjectTagReleases < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_releases_on_project_tag_released_at'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :releases, name: INDEX_NAME
  end

  def down
    add_concurrent_index :releases,
                         %i[project_id tag released_at],
                         name: INDEX_NAME
  end
end
