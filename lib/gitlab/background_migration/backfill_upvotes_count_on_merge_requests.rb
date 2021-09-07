# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class that will populate the upvotes_count field for each merge request
    class BackfillUpvotesCountOnMergeRequests
      BATCH_SIZE = 500

      # rubocop: disable Style/Documentation
      class AwardEmoji < ActiveRecord::Base
        include EachBatch

        self.table_name = 'award_emoji'
      end
      # rubocop: enable Style/Documentation

      def perform(start_id, stop_id)
        AwardEmoji.where(id: start_id..stop_id, name: 'thumbsup', awardable_type: 'MergeRequest').each_batch(of: BATCH_SIZE) do |batch|
          update_merge_requests_upvotes_count(batch)
        end
      end

      private

      def execute(sql)
        @connection ||= ::ActiveRecord::Base.connection
        @connection.execute(sql)
      end

      def update_merge_requests_upvotes_count(batch)
        execute(<<~SQL)
          WITH batched_relation AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (#{batch.select(:awardable_id).limit(BATCH_SIZE).to_sql})
          UPDATE merge_requests
          SET upvotes_count = sub_q.count_all
          FROM (
            SELECT COUNT(*) AS count_all, e.awardable_id AS merge_request_id
            FROM batched_relation AS e
            GROUP BY merge_request_id
          ) AS sub_q
          WHERE sub_q.merge_request_id = merge_requests.id;
        SQL
      end
    end
  end
end
