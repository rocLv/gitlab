# frozen_string_literal: true

class JiraConnect::OauthCallbacksController < JiraConnect::ApplicationController
  layout 'jira_connect'

  skip_before_action :verify_atlassian_jwt!

  def index
    payload, _ = Atlassian::Jwt.decode(jwt, nil, false)
    installation = JiraConnectInstallation.find_by_client_key(payload['iss'])

    redirect_to redirect_url(installation)
  end

  private

  def state
    state_param = URI.decode(params[:state]).split('::')

    {
      jwt: state_param.first,
      referrer: state_param.last
    }
  end

  def jwt
    state[:jwt]
  end

  def jira_connect_app_path
    URI( state[:referrer]).path
  end

  def redirect_url(installation)
    URI::HTTPS.build(host: installation.base_url.gsub('https://', ''), path: jira_connect_app_path, query: { code: params[:code] }.to_query).to_s
  end
end
