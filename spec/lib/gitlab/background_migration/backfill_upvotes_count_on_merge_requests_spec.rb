# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillUpvotesCountOnMergeRequests do
  let_it_be(:award_emoji) { table(:award_emoji) }
  let_it_be(:merge_requests) { table(:merge_requests) }
  let_it_be(:projects) { table(:projects) }
  let_it_be(:namespaces) { table(:namespaces) }

  let!(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace') }
  let!(:project_1) {projects.create!(namespace_id: namespace.id) }
  let!(:project_2) { projects.create!(namespace_id: namespace.id) }
  let!(:merge_request_1) { merge_requests.create!(target_project_id: project_1.id, target_branch: 'default', source_branch: 'feature-1', title: 'merge request') }
  let!(:merge_request_2) { merge_requests.create!(target_project_id: project_2.id, target_branch: 'default', source_branch: 'feature-2', title: 'merge request') }
  let!(:merge_request_3) { merge_requests.create!(target_project_id: project_2.id, target_branch: 'default', source_branch: 'feature-3', title: 'merge request') }
  let!(:merge_request_4) { merge_requests.create!(target_project_id: project_2.id, target_branch: 'default', source_branch: 'feature-4', title: 'merge request') }

  describe '#perform' do
    before do
      add_upvotes(merge_request_1, :thumbsdown, 1)
      add_upvotes(merge_request_2, :thumbsup, 2)
      add_upvotes(merge_request_2, :thumbsdown, 1)
      add_upvotes(merge_request_3, :thumbsup, 3)
      add_upvotes(merge_request_4, :thumbsup, 4)
    end

    it 'updates upvotes_count' do
      subject.perform(merge_request_1.id, merge_request_4.id)

      expect(merge_request_1.reload.upvotes_count).to eq(0)
      expect(merge_request_2.reload.upvotes_count).to eq(2)
      expect(merge_request_3.reload.upvotes_count).to eq(3)
      expect(merge_request_4.reload.upvotes_count).to eq(4)
    end
  end

  private

  def add_upvotes(merge_request, name, count)
    count.times do
      award_emoji.create!(
        name: name.to_s,
        awardable_type: 'MergeRequest',
        awardable_id: merge_request.id
      )
    end
  end
end
