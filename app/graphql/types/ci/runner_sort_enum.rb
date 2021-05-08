# frozen_string_literal: true

module Types
  module Ci
    class RunnerSortEnum < BaseEnum
      graphql_name 'CiRunnerSort'
      description 'Values for sorting runners'

      value 'CONTACTED_ASC', 'Ordered by contacted_at in ascending order.', value: :contacted_asc
      value 'CREATED_ASC', 'Ordered by created_date in ascending order.', value: :created_date
    end
  end
end
