# frozen_string_literal: true

class BackfillMergeRequestsUpvotesCount < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  MIGRATION = 'BackfillUpvotesCountOnMergeRequests'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 5_000

  class AwardEmoji < ActiveRecord::Base
    include EachBatch

    self.table_name = 'award_emoji'
  end

  def up
    scope = AwardEmoji.where(awardable_type: 'MergeRequest').where(name: 'thumbsup')

    queue_background_migration_jobs_by_range_at_intervals(
      scope,
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      primary_column_name: :awardable_id
    )
  end

  def down
    # no-op
  end
end
