# frozen_string_literal: true

class RemoveDuplicateProjectTagReleases < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    Project.all.each_batch(of: 50) do |projects|
      execute(
        "SELECT project_id, tag, MAX(released_at) as max FROM releases WHERE project_id IN (#{projects.pluck(:id).join(",")}) GROUP BY project_id, tag HAVING COUNT(*) > 1"
      ).each do |result|
        execute(
          ActiveRecord::Base.sanitize_sql(
            [
              "DELETE FROM releases WHERE project_id = ? AND tag = ? AND (released_at < ?)",
              result["project_id"],
              result["tag"],
              result["max"]
            ]
          )
        )
      end
    end
  end

  def down
    # no-op
    #
    # releases with the same tag within a project have been removed
    # and therefore the duplicate release data is no longer available
  end
end
