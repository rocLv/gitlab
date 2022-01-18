# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Expiring Subscription Message', :js, :freeze_time do
  shared_examples 'no expiration notification' do
    it 'loads the page without any subscription expiration notifications' do
      expect(page).not_to have_content('Your subscription expired!')
      expect(page).not_to have_content('Your subscription will expire')
    end
  end

  context 'for self-managed subscriptions' do
    context 'when signed in user is an admin' do
      let_it_be(:admin) { create(:admin) }

      before do
        create_current_license(plan: License::ULTIMATE_PLAN, expires_at: expires_at)

        sign_in(admin)
        gitlab_enable_admin_mode_sign_in(admin)
      end

      context 'with a license with no expiration' do
        let(:expires_at) { nil }

        include_examples 'no expiration notification'
      end

      context 'with an expired license' do
        let(:expires_at) { Date.current - 1.day }

        it 'notifies the admin of the expired subscription' do
          expect(page).to have_content('Your subscription expired!')
        end
      end

      context 'with a license expiring in 15 days' do
        let(:expires_at) { Date.current + 15.days }

        it 'notifies the admin of a soon expiring subscription' do
          expect(page).to have_content('Your subscription will expire in 15 days')
        end
      end

      context 'with a license expiring in more than 15 days' do
        let(:expires_at) { Date.current + 16.days }

        include_examples 'no expiration notification'
      end
    end

    context 'when signed in user is not an admin' do
      let_it_be(:user) { create(:user) }

      before do
        create_current_license(plan: License::ULTIMATE_PLAN, expires_at: expires_at, block_changes_at: block_changes_at)

        sign_in(user)
        visit root_path
      end

      context 'with a license with no expiration' do
        let(:expires_at) { nil }
        let(:block_changes_at) { nil }

        include_examples 'no expiration notification'
      end

      context 'with an expired license in the grace period' do
        let(:expires_at) { Date.current - 1.day }
        let(:block_changes_at) { Date.current + 13.days }

        include_examples 'no expiration notification'
      end

      context 'with an expired license beyond the grace period' do
        let(:expires_at) { Date.current - 15.days }
        let(:block_changes_at) { Date.current - 1.day }

        it 'notifies the admin of the expired subscription' do
          expect(page).to have_content('Your subscription expired!')
        end
      end
    end
  end

  context 'for namespace subscriptions', :saas do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }

    before do
      enable_namespace_license_check!

      create(:gitlab_subscription, namespace: group, end_date: end_date, auto_renew: false)

      allow_next_instance_of(GitlabSubscriptions::CheckFutureRenewalService, namespace: group) do |service|
        allow(service).to receive(:execute).and_return(false)
      end
    end

    context 'when signed in user is a group owner' do
      before do
        group.add_owner(user)

        sign_in(user)
        visit group_path(group)
      end

      context 'with an expired license' do
        let(:end_date) { Date.current - 1.day }

        it 'notifies the group owner of the expired subscription' do
          expect(page).to have_content('Your subscription expired!')
        end
      end

      context 'with a license expiring in less than 30 days' do
        let(:end_date) { Date.current + 29.days }

        it 'notifies the group owner of a soon expiring subscription' do
          expect(page).to have_content('Your subscription will expire in 29 days')
        end
      end

      context 'with a license expiring in 30 or more days' do
        let(:end_date) { Date.current + 30.days }

        include_examples 'no expiration notification'
      end
    end

    context 'when signed in user is not a group owner' do
      before do
        group.add_developer(user)

        sign_in(user)
        visit group_path(group)
      end

      context 'with an expired license' do
        let(:end_date) { Date.current - 1.day }

        include_examples 'no expiration notification'
      end

      context 'with a license expiring in less than 30 days' do
        let(:end_date) { Date.current + 29.days }

        include_examples 'no expiration notification'
      end
    end
  end
end
