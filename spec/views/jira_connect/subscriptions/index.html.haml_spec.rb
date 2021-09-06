# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'jira_connect/subscriptions/index.html.haml' do
  let(:user) { build_stubbed(:user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    assign(:subscriptions, [])
  end

  context 'when jira_connect_oauth feature flag is disabled' do
    before do
      stub_feature_flags(jira_connect_oauth: false)
    end

    context 'when the user is signed in' do
      it 'shows link to user profile' do
        render

        expect(rendered).to have_link(user.to_reference)
      end
    end

    context 'when the user is not signed in' do
      let(:user) { nil }

      it 'shows "Sign in" link' do
        render

        expect(rendered).to have_link('Sign in to GitLab')
      end
    end
  end
end
