# frozen_string_literal: true

class JiraConnect::OauthCallbacksController < JiraConnect::ApplicationController
  layout 'jira_connect'

  skip_before_action :verify_atlassian_jwt!

  def index; end
end
