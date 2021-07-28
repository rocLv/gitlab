# frozen_string_literal: true

module JiraConnectHelper

  def jira_connect_oauth
    code_verifier = SecureRandom.hex(128)

    {
      # We should give the frontend the URL for the POST of the PKCE code flow here:
      oauth_callback_url: 'TODO',
      code_verifier: code_verifier,
      code_challenge: Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier))
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
