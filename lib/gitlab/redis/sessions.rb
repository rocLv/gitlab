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

      # ::Redis::Store uses the default Serializer for (un)marshaling values. We want to avoid that.
      def self.pool
        @pool ||= ConnectionPool.new(size: pool_size) { store(serializer: nil) }
      end

      # We consider MultiStore ready for being enabled via Feature Flags when it was properly initialized.
      # In our case, it means that we explicitly set particular ENV var and no fallback for configuration happened.
      def self.multistore_configured?
        Gitlab::Utils.to_boolean(ENV["REDIS_SESSIONS_MULTISTORE_CONFIGURED"]) && !using_config_fallback?
      end

      def store(extras = {})
        return super unless self.class.multistore_configured?

        MultiStore.new(redis_store_options.merge(extras), self.class.config_fallback.params.merge(extras))
      end
    end
  end
end
