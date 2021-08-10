# frozen_string_literal: true

module JiraConnectHelper
  def jira_connect_app_data(subscriptions)
    skip_groups = subscriptions.map(&:namespace_id)

    {
      groups_path: api_v4_groups_path(params: { min_access_level: Gitlab::Access::MAINTAINER, skip_groups: skip_groups }),
      subscriptions: subscriptions.map { |s| serialize_subscription(s) }.to_json,
      subscriptions_path: jira_connect_subscriptions_path,
      users_path: current_user ? nil : jira_connect_users_path
    }
  end

  def jira_connect_oauth_data
    return unless Feature.enabled?(:jira_connect_oauth)

    oauth_authorize_url = oauth_authorization_url(
      client_id: ENV['JIRA_CONNECT_OAUTH_CLIENT_ID'],
      response_type: 'code',
      scope: 'api',
      code_challenge: oauth_code_challange,
      code_challenge_method: 'S256',
      redirect_uri: jira_connect_oauth_callbacks_url,
      state: oauth_state
    )

    {
      oauth_authorize_url: oauth_authorize_url,
      oauth_token_url: oauth_token_url,
      state: oauth_state,
      oauth_token_payload: {
        grant_type: :authorization_code,
        client_id: ENV['JIRA_CONNECT_OAUTH_CLIENT_ID'],
        redirect_uri: jira_connect_oauth_callbacks_url,
        code_verifier: oauth_code_verifier
      }
    }
  end

  private

  def oauth_code_challange
    Base64.urlsafe_encode64(Digest::SHA256.digest(oauth_code_verifier), padding: false)
  end

  def oauth_state
    @oauth_state ||= SecureRandom.hex(32)
  end

  def oauth_code_verifier
    @oauth_code_verifier ||= SecureRandom.alphanumeric(128)
  end

  def serialize_subscription(subscription)
    {
      group: {
        name: subscription.namespace.name,
        avatar_url: subscription.namespace.avatar_url,
        full_name: subscription.namespace.full_name,
        description: subscription.namespace.description
      },
      created_at: subscription.created_at,
      unlink_path: jira_connect_subscription_path(subscription)
    }
  end
end
