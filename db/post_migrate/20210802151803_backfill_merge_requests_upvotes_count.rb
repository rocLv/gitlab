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
    merge_request_award_emoji = define_batchable_model('award_emoji').where(awardable_type: 'MergeRequest', name: 'thumbsup')

    queue_background_migration_jobs_by_range_at_intervals(
      merge_request_award_emoji,
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # no-op
  end
end
