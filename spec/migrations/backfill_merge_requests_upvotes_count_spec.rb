# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillMergeRequestsUpvotesCount, :migration do
  let_it_be(:merge_requests) { table(:merge_requests) }
  let_it_be(:award_emoji) { table(:award_emoji) }
  let_it_be(:namespace) { table(:namespaces).create!(name: 'name', path: 'path') }
  let_it_be(:project) { table(:projects).create!(namespace_id: namespace.id) }
  let_it_be(:merge_request_1) { merge_requests.create!(target_project_id: project.id, source_branch: 'branch_1', target_branch: 'master') }
  let_it_be(:merge_request_2) { merge_requests.create!(target_project_id: project.id, source_branch: 'branch_2', target_branch: 'master') }
  let_it_be(:merge_request_3) { merge_requests.create!(target_project_id: project.id, source_branch: 'branch_3', target_branch: 'master') }
  let_it_be(:merge_request_4) { merge_requests.create!(target_project_id: project.id, source_branch: 'branch_4', target_branch: 'master') }
  let_it_be(:merge_request_5) { merge_requests.create!(target_project_id: project.id, source_branch: 'branch_5', target_branch: 'master') }
  let_it_be(:award_emoji_1_1) { award_emoji.create!(name: 'thumbsup', awardable_type: 'MergeRequest', awardable_id: merge_request_1.id) }
  let_it_be(:award_emoji_1_2) { award_emoji.create!(name: 'thumbsup', awardable_type: 'MergeRequest', awardable_id: merge_request_1.id) }
  let_it_be(:award_emoji_1_3) { award_emoji.create!(name: 'thumbsup', awardable_type: 'MergeRequest', awardable_id: merge_request_1.id) }
  let_it_be(:award_emoji_2_1) { award_emoji.create!(name: 'thumbsup', awardable_type: 'MergeRequest', awardable_id: merge_request_2.id) }
  let_it_be(:award_emoji_2_2) { award_emoji.create!(name: 'thumbsup', awardable_type: 'MergeRequest', awardable_id: merge_request_2.id) }
  let_it_be(:award_emoji_3_1) { award_emoji.create!(name: 'thumbsup', awardable_type: 'MergeRequest', awardable_id: merge_request_3.id) }
  let_it_be(:award_emoji_4_1) { award_emoji.create!(name: 'thumbsdown', awardable_type: 'MergeRequest', awardable_id: merge_request_4.id) }
  let_it_be(:award_emoji_5_1) { award_emoji.create!(name: 'thumbsup', awardable_type: 'MergeRequest', awardable_id: merge_request_5.id) }
  let_it_be(:award_emoji_5_2) { award_emoji.create!(name: 'thumbsup', awardable_type: 'MergeRequest', awardable_id: merge_request_5.id) }

  describe '#up' do
    it 'correctly schedules background migrations', :aggregate_failures do
      stub_const("#{described_class}::BATCH_SIZE", 2)

      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(described_class::MIGRATION).to be_scheduled_migration(merge_request_1.id, merge_request_2.id)
          expect(described_class::MIGRATION).to be_scheduled_migration(merge_request_3.id, merge_request_5.id)
          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end
  end
end
