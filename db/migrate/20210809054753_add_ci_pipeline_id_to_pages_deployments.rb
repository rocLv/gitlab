# frozen_string_literal: true

class AddCiPipelineIdToPagesDeployments < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!


  def up
    with_lock_retries do
      add_column :pages_deployments, :ci_pipeline_id, :integer
    end

    add_concurrent_foreign_key :pages_deployments, :ci_pipelines, column: :ci_pipeline_id, on_delete: :nullify
  end

  def down
    remove_foreign_key_without_error :pages_deployments, column: :ci_pipeline_id

    with_lock_retries do
      remove_column :pages_deployments, :ci_pipeline_id
    end
  end
end
