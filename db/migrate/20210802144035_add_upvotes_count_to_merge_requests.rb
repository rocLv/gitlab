# frozen_string_literal: true

class AddUpvotesCountToMergeRequests < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :merge_requests, :upvotes_count, :integer, default: 0, null: false
    end
  end

  def down
    remove_column :merge_requests, :upvotes_count
  end
end
