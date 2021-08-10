# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectHelper do
  describe '#jira_connect_app_data' do
    let_it_be(:subscription) { create(:jira_connect_subscription) }

    let(:user) { create(:user) }

    subject { helper.jira_connect_app_data([subscription]) }

    context 'user is not logged in' do
      before do
        allow(view).to receive(:current_user).and_return(nil)
      end

      it 'includes Jira Connect app attributes' do
        is_expected.to include(
          :groups_path,
          :subscriptions_path,
          :users_path
        )
      end

      it 'assigns users_path with value' do
        expect(subject[:users_path]).to eq(jira_connect_users_path)
      end

      it 'passes group as "skip_groups" param' do
        skip_groups_param = CGI.escape('skip_groups[]')

        expect(subject[:groups_path]).to include("#{skip_groups_param}=#{subscription.namespace.id}")
      end
    end

    context 'user is logged in' do
      before do
        allow(view).to receive(:current_user).and_return(user)
      end

      it 'assigns users_path to nil' do
        expect(subject[:users_path]).to be_nil
      end
    end
  end

  describe '#jira_connect_oauth_data' do
    subject(:oauth_data) { helper.jira_connect_oauth_data }

    let(:client_id) { '123' }

    before do
      stub_env('JIRA_CONNECT_OAUTH_CLIENT_ID', client_id)
    end

    context 'jira_connect_oauth feature is disabled' do
      before do
        stub_feature_flags(jira_connect_oauth: false)
      end

      it { is_expected.to be_nil }
    end

    specify do
      expect(oauth_data).to include(
        oauth_authorize_url: %r/http:\/\/test.host\/oauth\/authorize\?(.*)/,
        oauth_token_url: 'http://test.host/oauth/token',
        state: %r/[a-z0-9.]{32}/,
        oauth_token_payload: hash_including(
          grant_type: :authorization_code,
          client_id: client_id,
          redirect_uri: 'http://test.host/-/jira_connect/oauth_callbacks',
          code_verifier: %r/[a-zA-Z0-9.]{128}/
        )
      )
    end

    it 'includes a authorize_url with all params' do
      params = Rack::Utils.parse_nested_query(URI.parse(oauth_data[:oauth_authorize_url]).query)

      expect(params).to include(
        'client_id' => client_id,
        'response_type' => 'code',
        'scope' => 'api',
        'code_challenge' => Base64.urlsafe_encode64(Digest::SHA256.digest(oauth_data.dig(:oauth_token_payload, :code_verifier)), padding: false),
        'code_challenge_method' => 'S256',
        'redirect_uri' => 'http://test.host/-/jira_connect/oauth_callbacks',
        'state' => oauth_data[:state]
      )
    end
  end
end
