# frozen_string_literal: true

class BackfillGroupFeatures < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'BackfillGroupFeatures'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000

  disable_ddl_transaction!

  class Namespace < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'namespaces'

    scope :group_namespaces, -> { where(type: 'Group') }
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(Namespace.group_namespaces, MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
    # NOOP
  end
end
