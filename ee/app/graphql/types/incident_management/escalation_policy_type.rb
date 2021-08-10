# frozen_string_literal: true

module Types
  module IncidentManagement
    class EscalationPolicyType < BaseObject
      graphql_name 'EscalationPolicyType'
      description 'Represents an escalation policy'

      authorize :read_incident_management_escalation_policy

      field :id, Types::GlobalIDType[::IncidentManagement::EscalationPolicy],
            null: true,
            description: 'ID of the escalation policy.'

      field :name, GraphQL::Types::String,
            null: true,
            description: 'The name of the escalation policy.'

      field :description, GraphQL::Types::String,
            null: true,
            description: 'The description of the escalation policy.'

      field :rules, [Types::IncidentManagement::EscalationRuleType],
            null: true,
            description: 'Steps of the escalation policy.',
            method: :active_rules

      field :on_call_users, [Types::IncidentManagement::OncallUserType],
            null: true,
            description: 'Current oncall users for the escalation policy.',
            resolver: ::Resolvers::IncidentManagement::EscalationPolicyOncallUsersResolver
    end
  end
end
