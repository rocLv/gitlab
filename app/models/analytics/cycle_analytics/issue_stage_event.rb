# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class IssueStageEvent < ApplicationRecord
      include StageEventModel
      extend SuppressCompositePrimaryKeyWarning

      validates(*%i[stage_event_hash_id issue_id group_id project_id start_event_timestamp], presence: true)

      def self.issuable_id_column
        :issue_id
      end
    end
  end
end
