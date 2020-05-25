# frozen_string_literal: true

module Ci
  class InstanceVariable < ApplicationRecord
    extend Gitlab::Ci::Model
    extend Gitlab::ProcessMemoryCache::Helper
    include Ci::NewHasVariable
    include Ci::Maskable

    alias_attribute :secret_value, :value

    validates :key, uniqueness: {
      message: "(%{value}) has already been taken"
    }

    scope :unprotected, -> { where(protected: false) }

    after_commit { self.class.invalidate_memory_cache(:ci_instance_variable_data) }

    class << self
      def all_cached
        cached_data[:all]
      end

      def unprotected_cached
        cached_data[:unprotected]
      end

      private

      def cached_data
        fetch_memory_cache(:ci_instance_variable_data) do
          all_records = unscoped.all.to_a

          { all: all_records, unprotected: all_records.reject(&:protected?) }
        end
      end
    end
  end
end
