# frozen_string_literal: true

module Gitlab
  module Auth
    module GroupSaml
      class SessionEnforcer
        def initialize(user, group)
          @user = user
          @group = group
        end

        def access_restricted?
          return false if skip_check?

          !active_session?
        end

        def api_access_restricted?
          access_restricted? && api_check_enforced?
        end

        def git_access_restricted?
          access_restricted? && git_check_enforced?
        end

        # SSO enforcement for Dependency proxy is configured by the same
        # configuration option. See https://gitlab.com/gitlab-org/gitlab/-/issues/337969
        alias_method :dependency_proxy_access_restricted?, :git_access_restricted?

        private

        attr_reader :user, :group

        def skip_check?
          return true if no_group_or_provider?
          return true if user_allowed?
          return true unless enforced_sso?

          false
        end

        def no_group_or_provider?
          return true unless group
          return true unless group.root_ancestor
          return true unless saml_provider

          false
        end

        def saml_provider
          @saml_provider ||= group.root_ancestor.saml_provider
        end

        def enforced_sso?
          saml_provider.enforced_sso?
        end

        def api_check_enforced?
          saml_provider.api_check_enforced?
        end

        def git_check_enforced?
          saml_provider.git_check_enforced?
        end

        def user_allowed?
          return true if user.bot?
          return true if user.auditor? || user.can_read_all_resources?
          return true if group.owned_by?(user)

          false
        end

        def active_session?
          latest_sign_in = find_latest_sign_in

          return false unless latest_sign_in
          return SsoEnforcer::DEFAULT_SESSION_TIMEOUT.ago < latest_sign_in if ::Feature.enabled?(:enforced_sso_expiry, group)

          true
        end

        def find_latest_sign_in
          sessions = ActiveSession.list_sessions(user)
          sessions.filter_map do |session|
            Gitlab::NamespacedSessionStore.new(SsoState::SESSION_STORE_KEY, session.with_indifferent_access)[saml_provider.id]
          end.max
        end
      end
    end
  end
end
