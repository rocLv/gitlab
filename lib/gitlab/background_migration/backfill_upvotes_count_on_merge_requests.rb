# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class that will populate the upvotes_count field
    # for each merge request
    class BackfillUpvotesCountOnMergeRequests
      BATCH_SIZE = 1_000

      def perform(start_id, stop_id)
        (start_id..stop_id).step(BATCH_SIZE).each do |offset|
          update_merge_requests_upvotes_count(offset, offset + BATCH_SIZE)
        end
      end

      private

      def execute(sql)
        @connection ||= ::ActiveRecord::Base.connection
        @connection.execute(sql)
      end

      def update_merge_requests_upvotes_count(batch_start, batch_stop)
        execute(<<~SQL)
          UPDATE merge_requests
          SET upvotes_count = sub_q.count_all
          FROM (
            SELECT COUNT(*) AS count_all, e.awardable_id AS merge_request_id
            FROM award_emoji AS e
            WHERE e.name = 'thumbsup' AND
            e.awardable_type = 'MergeRequest' AND
            e.awardable_id BETWEEN #{batch_start} AND #{batch_stop}
            GROUP BY merge_request_id
          ) AS sub_q
          WHERE sub_q.merge_request_id = merge_requests.id;
        SQL
      end
    end
  end
end
