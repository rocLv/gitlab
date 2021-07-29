# frozen_string_literal: true

module JiraConnectHelper

  def jira_connect_oauth
    client_id = '9954b598535e466bd278bd834493dd5c2f56f1c07a6a3c71e1137f01fef1b2d2'
    # Eipi: While testing I have found that we actually do not need the SECRET :thinking:
    client_secret = '8a438d5dca6d8a7c603366f2b3d470bd35c5f99e3d882f1864b9cec547539a88'
    code_verifier = SecureRandom.alphanumeric(128)
    # Eipi: The padding: false was important
    code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
    # Eipi: Still adding a state, so that we can check against csrf
    state = SecureRandom.hex(32)
    redirect_uri = jira_connect_oauth_callbacks_url

    oauth_token_payload = {
      grant_type: 'authorization_code',
      client_id: client_id,
      redirect_uri: redirect_uri,
      code_verifier: code_verifier
    }

    {
      # We should give the frontend the URL for the POST of the PKCE code flow here:
      oauth_authorize_url: oauth_authorization_url(client_id: client_id, response_type: 'code', scope: 'api', code_challenge: code_challenge, code_challenge_method: 'S256', redirect_uri: redirect_uri, state: state),
      oauth_token_url: oauth_token_url,
      oauth_token_payload: oauth_token_payload,
      state: state
    }
  end

  def jira_connect_app_data(subscriptions)
    skip_groups = subscriptions.map(&:namespace_id)

    {
      groups_path: api_v4_groups_path(params: { min_access_level: Gitlab::Access::MAINTAINER, skip_groups: skip_groups }),
      subscriptions: subscriptions.map { |s| serialize_subscription(s) }.to_json,
      subscriptions_path: jira_connect_subscriptions_path,
      users_path: current_user ? nil : jira_connect_users_path
    }
  end

  private

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
