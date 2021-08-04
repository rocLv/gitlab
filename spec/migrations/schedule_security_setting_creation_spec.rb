# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleSecuritySettingCreation, :sidekiq do
  describe '#up' do
    let(:projects) { table(:projects) }
    let(:namespaces) { table(:namespaces) }

    it 'schedules background migration job' do
      namespace = namespaces.create!(name: 'test', path: 'test')
      projects.create!(id: 12, namespace_id: namespace.id, name: 'gitlab', path: 'gitlab')

      Sidekiq::Testing.fake! do
        expect { migrate! }.to change { BackgroundMigrationWorker.jobs.size }.by(1)
      end
    end
  end
end
