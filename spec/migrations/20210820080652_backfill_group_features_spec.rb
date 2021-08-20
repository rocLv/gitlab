# frozen_string_literal: true

require 'spec_helper'
require_migration!('backfill_group_features')

RSpec.describe BackfillGroupFeatures, :migration do
  let(:namespaces) { table(:namespaces) }

  describe '#up' do
    it 'schedules BackfillGroupFeatures background jobs' do
      stub_const("#{described_class}::BATCH_SIZE", 2)

      namespaces.create!(id: 1, name: 'group1', path: 'group1', type: 'Group')
      namespaces.create!(id: 2, name: 'user', path: 'user')
      namespaces.create!(id: 3, name: 'group2', path: 'group2', type: 'Group')
      namespaces.create!(id: 4, name: 'group3', path: 'group3', type: 'Group')

      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, 1, 3)
          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, 4, 4)
          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end
  end
end
