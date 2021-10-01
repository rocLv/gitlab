# frozen_string_literal: true

module Gitlab
  module Parallel
    class << self
      def execute(objects, &block)
        promises = objects.map do |object|
          Concurrent::Promise.new { yield(object) }.execute
        end

        promises.map do |promise|
          promise.wait

          if promise.fulfilled?
            promise.value
          else
            raise promise.reason
          end
        end
      end
    end
  end
end
