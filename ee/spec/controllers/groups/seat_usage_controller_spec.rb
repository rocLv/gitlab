# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SeatUsageController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }

  describe 'GET show' do
    before do
      sign_in(user)
      stub_application_setting(check_namespace_plan: true)
    end

    def get_show
      get :show, params: { group_id: group }
    end

    subject { response }

    context 'when authorized' do
      before do
        group.add_owner(user)
      end

      it 'renders show with 200 status code' do
        get_show

        is_expected.to have_gitlab_http_status(:ok)
        is_expected.to render_template(:show)
      end
    end

    context 'when unauthorized' do
      before do
        group.add_developer(user)
      end

      it 'renders 403 when user is not an owner' do
        get_show

        is_expected.to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'POST export' do
    before do
      sign_in(user)
      stub_application_setting(check_namespace_plan: true)
    end

    def request_csv
      post :export, params: { group_id: group }
    end

    context 'when authorized' do
      before do
        group.add_owner(user)
      end

      context 'when seat_usage_export feature flag is enabled' do
        before do
          stub_feature_flags(seat_usage_export: true)
        end

        it 'redirects to seat usage page' do
          expect(Groups::SeatUsageExportCsvWorker).to receive(:perform_async).with(group.id, user.id)

          request_csv

          expect(response).to redirect_to group_seat_usage_path
          expect(controller).to set_flash[:notice].to(_("Your CSV export has started. It will be emailed to #{user.notification_email} when complete."))
        end
      end

      context 'when seat_usage_export feature flag is disabled' do
        before do
          stub_feature_flags(seat_usage_export: false)
        end

        it 'responds with 404 Not Found' do
          request_csv

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when unauthorized' do
      before do
        group.add_developer(user)
      end

      it 'renders 404 when user is not an owner' do
        request_csv

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
