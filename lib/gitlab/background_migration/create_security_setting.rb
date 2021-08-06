# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class CreateSecuritySetting
      def perform(from_id, to_id)
      end
    end
  end
end

Gitlab::BackgroundMigration::CreateSecuritySetting.prepend_mod_with('EE::Gitlab::BackgroundMigration::CreateSecuritySetting')
