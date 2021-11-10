# frozen_string_literal: true

module Gitlab
  module Redis
    class SharedState < ::Gitlab::Redis::Wrapper
      # Could remove these consts after replacing Gitlab::Redis::SharedState calls
      # with Gitlab::Redis::Sessions where applicable.
      SESSION_NAMESPACE = 'session:gitlab'
      USER_SESSIONS_NAMESPACE = 'session:user:gitlab'
      USER_SESSIONS_LOOKUP_NAMESPACE = 'session:lookup:user:gitlab'
      IP_SESSIONS_LOOKUP_NAMESPACE = 'session:lookup:ip:gitlab2'
    end
  end
end
