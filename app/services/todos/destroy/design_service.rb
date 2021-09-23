# frozen_string_literal: true

module Todos
  module Destroy
    # Service class for deleting todos that belongs to a deleted/archived design.
    class DesignService
      attr_reader :design_ids

      def initialize(design_ids)
        @design_ids = design_ids
      end

      def execute
        todos.delete_all
      end

      private

      def todos
        Todo.for_target(archived_designs.select(:design_id)).for_type(DesignManagement::Design)
      end

      def archived_designs
        DesignManagement::Action.by_design(design_ids).by_event(:deletion)
      end
    end
  end
end
