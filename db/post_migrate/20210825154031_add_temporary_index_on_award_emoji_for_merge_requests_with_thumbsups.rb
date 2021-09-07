# frozen_string_literal: true

class AddTemporaryIndexOnAwardEmojiForMergeRequestsWithThumbsups < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'tmp_idx_award_emoji_on_merge_requests_with_thumbsup'
  INDEX_CONDITION = "awardable_type = 'MergeRequest' AND name = 'thumbsup'"

  disable_ddl_transaction!

  def up
    # this index is used in db/post_migrate/20210802151803_backfill_merge_requests_upvotes_count
    add_concurrent_index :award_emoji, [:id, :awardable_id], where: INDEX_CONDITION, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :award_emoji, INDEX_NAME
  end
end
