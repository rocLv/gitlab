# frozen_string_literal: true

class RemoveDuplicateProjectTagReleases < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    ActiveRecord::Base.connection.execute <<~SQL
      delete from releases a using
        (SELECT project_id, tag, MAX(released_at) as max FROM releases GROUP BY project_id, tag HAVING COUNT(*) > 1) b
        where a.project_id = b.project_id
          and a.tag = b.tag
          and a.released_at < b.max;
    SQL
  end

  def down
    # no-op
    #
    # releases with the same tag within a project have been removed
    # and therefore the duplicate release data is no longer available
  end
end
