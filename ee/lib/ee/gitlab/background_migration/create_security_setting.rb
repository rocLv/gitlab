# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module CreateSecuritySetting
        extend ::Gitlab::Utils::Override

        class Project < ActiveRecord::Base
          self.table_name = 'projects'

          has_one :security_setting, class_name: 'ProjectSecuritySetting'

          scope :without_security_settings, -> { left_joins(:security_setting).where(project_security_settings: { project_id: nil }) }
        end

        class ProjectSecuritySetting < ActiveRecord::Base
          self.table_name = 'project_security_settings'

          belongs_to :project, inverse_of: :security_setting
        end

        override :perform
        def perform(from_id, to_id)
          projects = Project.without_security_settings.where(id: from_id..to_id)

          projects.each(&:create_security_setting)
        end
      end
    end
  end
end
