# frozen_string_literal: true

module Clusters
  class AgentAuthorizationsFinder
    def initialize(project)
      @project = project
    end

    def execute
      return [] unless feature_available?

      implicit_authorizations + group_authorizations
    end

    private

    attr_reader :project

    def feature_available?
      project.licensed_feature_available?(:cluster_agents)
    end

    def implicit_authorizations
      project.cluster_agents.map do |agent|
        Clusters::Agents::ImplicitAuthorization.new(agent: agent)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def group_authorizations
      return [] unless project.group

      authorizations = Clusters::Agents::GroupAuthorization.arel_table

      ordered_ancestors_cte = Gitlab::SQL::CTE.new(
        :ordered_ancestors,
        project.group.self_and_ancestors(hierarchy_order: :asc).reselect(:id)
      )

      cte_join_sources = authorizations.join(ordered_ancestors_cte.table).on(
        authorizations[:group_id].eq(ordered_ancestors_cte.table[:id])
      ).join_sources

      Clusters::Agents::GroupAuthorization
        .with(ordered_ancestors_cte.to_arel)
        .joins(cte_join_sources)
        .joins(agent: :project)
        .where('projects.namespace_id IN (SELECT id FROM ordered_ancestors)')
        .order(Arel.sql('agent_id, array_position(ARRAY(SELECT id FROM ordered_ancestors)::bigint[], agent_group_authorizations.group_id)'))
        .select('DISTINCT ON (agent_id) agent_group_authorizations.*')
        .preload(agent: :project)
        .to_a
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end