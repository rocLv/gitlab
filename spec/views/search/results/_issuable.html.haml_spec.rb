# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'search/results/_issuable' do
  subject { render partial: 'search/results/issuable', locals: { issuable: issuable } }

  shared_examples 'displays upvotes' do
    context 'when upvotes do not exist' do
      it 'does not show the thumbs up icon' do
        subject

        expect(rendered).not_to have_selector('[data-testid="thumb-up-icon"]')
      end
    end

    context 'when upvotes exist' do
      let!(:upvotes) { create_list(:award_emoji, 3, :upvote, awardable: issuable) }

      it 'shows upvotes for issuable' do
        subject

        expect(rendered).to have_selector('[data-testid="thumb-up-icon"]')
      end
    end
  end

  context 'issues' do
    let_it_be(:issuable) { create(:issue) }

    it_behaves_like 'displays upvotes'
  end

  context 'merge requests' do
    let!(:issuable) { create(:merge_request) }

    it_behaves_like 'displays upvotes'

    context 'when search_sort_merge_requests_by_popularity feature flag is disabled' do
      before do
        stub_feature_flags(search_sort_merge_requests_by_popularity: false)
      end

      context 'when upvotes exist' do
        let!(:upvotes) { create_list(:award_emoji, 3, :upvote, awardable: issuable) }

        it 'does not show upvotes for issuable' do
          subject

          expect(rendered).not_to have_selector('[data-testid="thumb-up-icon"]')
        end
      end
    end
  end
end
