# frozen_string_literal: true

class AddLockedToCiJobArtifacts < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database::SchemaHelpers

  FUNCTION_NAME = 'ci_job_artifacts_locked_from_ci_pipelines'
  TRIGGER_NAME = "#{FUNCTION_NAME}_update"
  LOCKED = Ci::JobArtifact.lockeds[:artifacts_locked]
  UNLOCKED = Ci::JobArtifact.lockeds[:unlocked]

  def up
    with_lock_retries do
      add_column :ci_job_artifacts, :locked, :smallint, default: LOCKED
    end

    create_trigger_function(FUNCTION_NAME, replace: true) do
      <<~SQL
        UPDATE ci_job_artifacts SET locked = NEW.locked
        FROM ci_builds
        WHERE ci_builds.id = ci_job_artifacts.job_id
          AND ci_builds.type = 'Ci::Build'
          AND ci_builds.commit_id = NEW.id;
        RETURN NULL;
      SQL
    end

    create_trigger(:ci_pipelines, TRIGGER_NAME, FUNCTION_NAME, fires: 'AFTER UPDATE')
  end

  def down
    drop_trigger(:ci_pipelines, TRIGGER_NAME)
    drop_function(FUNCTION_NAME)

    with_lock_retries do
      remove_column :ci_job_artifacts, :locked
    end
  end
end
