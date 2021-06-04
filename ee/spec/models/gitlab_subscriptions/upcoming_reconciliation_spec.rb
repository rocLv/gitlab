# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::UpcomingReconciliation do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace).optional }
  end

  describe 'validations' do
    # This is needed for the validate_uniqueness_of expectation.
    let_it_be(:upcoming_reconciliation) { create(:upcoming_reconciliation, :saas) }

    it { is_expected.to validate_uniqueness_of(:namespace) }

    it 'does not allow multiple rows with namespace_id nil' do
      create(:upcoming_reconciliation, :self_managed)

      expect { create(:upcoming_reconciliation, :self_managed) }.to raise_error(
        ActiveRecord::RecordInvalid,
        'Validation failed: Namespace has already been taken'
      )
    end

    context 'when gitlab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it { is_expected.to validate_presence_of(:namespace) }
    end

    context 'when not gitlab.com' do
      it { is_expected.not_to validate_presence_of(:namespace) }
    end
  end

  describe '#display_alert?' do
    let(:upcoming_reconciliation) { build(:upcoming_reconciliation, :saas) }

    subject(:display_alert?) { upcoming_reconciliation.display_alert? }

    context 'with next_reconciliation_date in future' do
      it { is_expected.to eq(true) }
    end

    context 'with next_reconciliation_date in past' do
      before do
        upcoming_reconciliation.next_reconciliation_date = Date.yesterday
      end

      it { is_expected.to eq(false) }
    end

    context 'with display_alert_from in future' do
      before do
        upcoming_reconciliation.display_alert_from = 2.days.from_now
      end

      it { is_expected.to eq(false) }
    end

    context 'with display_alert_from in past' do
      it { is_expected.to eq(true) }
    end
  end

  describe '.for_self_managed' do
    it 'returns row where namespace_id is nil' do
      upcoming_reconciliation = create(:upcoming_reconciliation, :self_managed)

      expect(described_class.for_self_managed).to eq(upcoming_reconciliation)
    end

    it 'returns nil when there is no row with namespace_id nil' do
      expect(described_class.for_self_managed).to eq(nil)
    end
  end
end
