# frozen_string_literal: true

module Gitlab
  module Redis
    class Sessions < ::Gitlab::Redis::Wrapper
      SESSION_NAMESPACE = 'session:gitlab'
      USER_SESSIONS_NAMESPACE = 'session:user:gitlab'
      USER_SESSIONS_LOOKUP_NAMESPACE = 'session:lookup:user:gitlab'
      IP_SESSIONS_LOOKUP_NAMESPACE = 'session:lookup:ip:gitlab2'

      # The data we store on Sessions used to be stored on SharedState.
      def self.config_fallback
        SharedState
      end

      def self.pool
        @pool ||= ConnectionPool.new(size: pool_size) { store(serializer: nil) }
      end

      def store(extras = {})
        if self.class.config_fallback? || Gitlab::Utils.to_boolean(ENV["REDIS_SESSIONS_FALLBACK_STRATEGY_DISABLED"])
          # Don't use multistore if redis.sessions configuration is not provided or fallback strategy env variable is disabled
          super
        else
          MultiStore.new(redis_store_options.merge(extras), self.class.config_fallback.params.merge(extras))
        end
      end
    end
  end
end
