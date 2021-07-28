# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SeatUsageExportCsvWorker do
  # it_behaves_like 'an idempotent worker' do
  #   let(:job_args) { [1, 2] }
  # end

  describe '#perform' do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:owner) { create(:user) }

    subject(:worker) { described_class.new }

    before do
      group.add_owner(owner)
    end

    it 'is a no-op if the group is not found' do
      expect(Groups::SeatUsageExportService).not_to receive(:execute)
      expect(worker.logger).to receive(:error).with("Failed to export CSV (user_id: #{owner.id}, group_id: 0): Couldn't find Group with 'id'=0")

      expect { worker.perform(0, owner.id) }.not_to raise_error
    end

    it 'is a no-op if the user is not found' do
      expect(Groups::SeatUsageExportService).not_to receive(:execute)
      expect(worker.logger).to receive(:error).with("Failed to export CSV (user_id: 0, group_id: #{group.id}): Couldn't find User with 'id'=0")

      expect { worker.perform(group.id, 0) }.not_to raise_error
    end

    it 'is a no-op if the group is a sub-group' do
      expect(Groups::SeatUsageExportService).not_to receive(:execute)

      subgroup = create(:group, :private, :nested)

      worker.perform(subgroup.id, owner.id)
    end

    it 'is a no-op if user is not allowed to manage group members' do
      developer = create(:user)
      group.add_developer(developer)

      expect(Groups::SeatUsageExportService).not_to receive(:execute)

      worker.perform(group.id, developer.id)
    end

    it 'delegates to the exeport service' do
      expect(Groups::SeatUsageExportService).to receive(:execute).with(group, owner)

      worker.perform(group.id, owner.id)
    end
  end
end
