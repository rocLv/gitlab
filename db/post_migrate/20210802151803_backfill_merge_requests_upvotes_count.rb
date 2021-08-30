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
    merge_request_award_emoji = AwardEmoji.where(awardable_type: 'MergeRequest').where(name: 'thumbsup')
    merge_request_award_emoji.each_batch(of: BATCH_SIZE, column: :awardable_id) do |batch, index|
      merge_request_ids = batch.pluck(:awardable_id)
      delay = index * DELAY_INTERVAL

      migrate_in(delay.seconds, MIGRATION, merge_request_ids)
    end
  end

  def down
    # no-op
  end
end
