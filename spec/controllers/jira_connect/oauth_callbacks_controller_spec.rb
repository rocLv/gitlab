# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::OauthCallbacksController do
  describe '#index' do
    context 'when logged in' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'renders an empty page' do
        get :index

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
