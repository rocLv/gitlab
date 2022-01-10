# frozen_string_literal: true

class RemoveDuplicateProjectTagReleases < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  BATCH_SIZE = 50

  def up
    count = execute("SELECT count(project_id) FROM releases GROUP BY project_id, tag HAVING COUNT(*) > 1").to_a
    count = count.empty? ? 0 : count[0]["count"]

    (0...count).step(BATCH_SIZE).each do |i|
      execute(
        "SELECT  project_id, tag, MAX(released_at) as max FROM releases GROUP BY project_id, tag HAVING COUNT(*) > 1 LIMIT #{BATCH_SIZE} OFFSET #{i}"
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
