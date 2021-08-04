# frozen_string_literal: true

class RateLimitedService
  attr_reader :object

  def initialize(key:, object_name:, project:, user:, rate_limiter: ::Gitlab::ApplicationRateLimiter)
    @key = key
    @project = project
    @user = user
    @rate_limiter = rate_limiter
    @rate_limited = rate_limiter.throttled?(key, scope: [project, user])

    define_singleton_method(object_name, method('object'))
  end

  def execute
    if rate_limited?
      nil
    else
      @object = yield
    end
  end

  def log_request(request)
    rate_limiter.log_request(request, "#{key}_request_limit".to_sym, user)
  end

  def rate_limited?
    @rate_limited
  end

  private

  attr_reader :key, :project, :user, :rate_limiter
end
