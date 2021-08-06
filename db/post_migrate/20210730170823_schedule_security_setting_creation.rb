# frozen_string_literal: true

class ScheduleSecuritySettingCreation < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  MIGRATION = 'CreateSecuritySetting'
  BATCH_SIZE = 1000
  INTERVAL = 5.minutes.to_i

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    include EachBatch

    self.table_name = 'projects'

    has_one :security_setting, class_name: 'ProjectSecuritySetting'

    scope :without_security_settings, -> { left_joins(:security_setting).where(project_security_settings: { project_id: nil }) }
  end

  class ProjectSecuritySetting < ActiveRecord::Base
    belongs_to :project, inverse_of: :security_setting
  end

  def up
    return unless Gitlab.ee? # Security Settings available only in EE version

    relation = Project.all
    queue_background_migration_jobs_by_range_at_intervals(relation,
                                                          MIGRATION,
                                                          INTERVAL,
                                                          batch_size: BATCH_SIZE)
  end

  # We're adding data so no need for rollback
  def down
  end
end
