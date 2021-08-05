# frozen_string_literal: true

class ScheduleSecuritySettingCreation < ActiveRecord::Migration[6.1]
  MIGRATION = 'CreateSecuritySetting'.freeze

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    has_one :security_setting, class_name: 'ProjectSecuritySetting'

    scope :without_security_settings, -> { left_joins(:security_setting).where(project_security_settings: { project_id: nil }) }
  end

  class ProjectSecuritySetting < ActiveRecord::Base
    belongs_to :project, inverse_of: :security_setting
  end

  def up
    return unless Gitlab.ee? # Security Settings available only in EE version

    Project.without_security_settings.select(:id).each_batch do |relation|
      project_ids = relation.pluck(:id)

      BackgroundMigrationWorker.perform_async([MIGRATION, project_ids])
    end
  end

  # We're adding data so no need for rollback
  def down
  end
end
