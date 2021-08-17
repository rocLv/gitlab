# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill group_features for a range of groups
    class BackfillGroupFeatures
      def perform(start_id, end_id)
        ActiveRecord::Base.connection.execute <<~SQL
          INSERT INTO group_features (group_id, created_at, updated_at)
            SELECT namespaces.id as group_id, now(), now()
            FROM namespaces
            WHERE namespaces.type = 'Group' AND namespaces.id BETWEEN #{start_id} AND #{end_id}
          ON CONFLICT (group_id) DO NOTHING;
        SQL
      end
    end
  end
end
