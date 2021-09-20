# frozen_string_literal: true

module Elastic
  module Latest
    module IssuableSort
      extend ::Gitlab::Utils::Override

      private

      override :apply_sort
      def apply_sort(query_hash, options)
        case ::Gitlab::Search::SortOptions.sort_and_direction(options[:order_by], options[:sort])
        when :popularity_asc
          query_hash.merge(sort: {
            upvotes: {
              order: 'asc'
            }
          })
        when :popularity_desc
          query_hash.merge(sort: {
            upvotes: {
              order: 'desc'
            }
          })
        else
          super
        end
      end
    end
  end
end
