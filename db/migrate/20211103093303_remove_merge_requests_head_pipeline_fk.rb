# frozen_string_literal: true

class RemoveMergeRequestsHeadPipelineFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    remove_foreign_key_if_exists(:merge_requests, :ci_pipelines, name: "fk_fd82eae0b9")
  end

  def down
    add_concurrent_foreign_key(:merge_requests, :ci_pipelines, name: "fk_fd82eae0b9", column: :head_pipeline_id, target_column: :id, on_delete: "cascade")
  end
end
