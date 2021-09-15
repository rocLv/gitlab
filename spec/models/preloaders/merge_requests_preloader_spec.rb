# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::MergeRequestsPreloader do
  describe '#execute' do
    it 'does not make n+1 queries' do
      create_list(:merge_request, 3)

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        load_merge_requests_and_upvote_counts
      end

      expect { load_merge_requests_and_upvote_counts }.not_to exceed_all_query_limit(control)
    end

    def load_merge_requests_and_upvote_counts
      merge_requests = MergeRequest.all

      described_class.new(merge_requests).execute

      # expectations make sure the queries execute
      merge_requests.each do |m|
        expect(m.target_project.project_feature).not_to be_nil
        expect(m.lazy_upvotes_count).to eq(0)
      end
    end
  end
end
