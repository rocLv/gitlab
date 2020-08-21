# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::RedisTrackEvent do
  let_it_be(:user) { create(:user) }

  describe 'POST /redis_track_event' do
    let(:endpoint) { '/redis_track_event' }
    let(:know_event) { 'g_compliance_dashboard' }
    let(:unknow_event) { 'unknow' }

    context 'when user is not authenticated' do
      it 'returns 401 error' do
        post api(endpoint), params: { name: know_event }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when name is missing from params' do
      it 'returns bad request' do
        post api(endpoint, user)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with correct params' do
      it 'returns status ok' do
        post api(endpoint, user), params: { name: know_event }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
