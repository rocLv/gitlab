# frozen_string_literal: true

module Resolvers
  module IncidentManagement
    class EscalationPolicyOncallUsersResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      alias_method :policy, :object

      type [Types::IncidentManagement::OncallUserType], null: true

      OncallUser = Struct.new(:user, :schedule)

      def resolve(**args)
        authorize!

        fetch_users_on_call.map { |h| OncallUser.new(h[:user], h[:schedule]) }
      end

      private

      def fetch_users_on_call
        users_on_call = []

        users_on_call << direct_recipients
        users_on_call << oncall_schedule_recipients

        users_on_call.flatten
      end

      def direct_recipients
        policy.rules.user_notify.map do |rule|
          {
            schedule: nil,
            user: rule.user
          }
        end
      end

      def oncall_schedule_recipients
        rotations = policy.oncall_rotations

        ::IncidentManagement::OncallUsersFinder.new(policy.project, rotations: rotations, include_schedule: true).execute
      end

      def authorize!
        Ability.allowed?(context[:current_user], :read_incident_management_escalation_policy, policy) || raise_resource_not_available_error!
      end
    end
  end
end
