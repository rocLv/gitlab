# frozen_string_literal: true

module Security
  module Ingestion
    module BulkInsertableTask
      include Gitlab::Utils::StrongMemoize

      def self.included(base)
        base.singleton_class.attr_accessor :model, :unique_by, :uses
      end

      def execute
        result_set

        after_ingest if uses
      end

      private

      delegate :unique_by, :model, :uses, :cast_values, to: :'self.class', private: true

      def return_data
        @return_data ||= result_set&.cast_values(model.attribute_types).to_a
      end

      def result_set
        strong_memoize(:result_set) do
          insert_attributes = attributes

          if insert_attributes
            ActiveRecord::InsertAll.new(model, insert_attributes, on_duplicate: on_duplicate, returning: uses, unique_by: unique_by).execute
          end
        end
      end

      def after_ingest
        raise "Implement the `after_ingest` template method!"
      end

      def attributes
        raise "Implement the `attributes` template method!"
      end

      def on_duplicate
        unique_by.present? ? :update : :skip
      end
    end
  end
end
