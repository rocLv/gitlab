# frozen_string_literal: true

class FixStateColumnInJobArtifactRegistry < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  # The following cop is disabled because of https://gitlab.com/gitlab-org/gitlab/issues/33470
  # rubocop:disable Migration/UpdateColumnInBatches
  def up
    update_column_in_batches(:job_artifact_registry, :state, 2) do |table, query|
      query.where(table[:success].eq(true)) # rubocop:disable CodeReuse/ActiveRecord
    end
  end
  # rubocop:enable Migration/UpdateColumnInBatches

  def down
    # no-op
  end
end
