# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::OauthCallbacksController do
  describe '#index' do
    it 'renders an empty page' do
      get :index

      expect(response).to have_gitlab_http_status(:ok)
    end
  end
end
