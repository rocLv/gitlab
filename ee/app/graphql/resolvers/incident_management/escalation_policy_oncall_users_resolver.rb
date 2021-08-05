# frozen_string_literal: true

module Resolvers
  module IncidentManagement
    class EscalationPolicyOncallUsersResolver < BaseResolver
      alias_method :policy, :object

      type [Types::IncidentManagement::OncallUserType], null: true

      OncallUser = Struct.new(:user, :schedule)

      def resolve(**args)
        oncall_user_hash = ::IncidentManagement::EscalationPolicyOncallUsersFinder.new(policy).execute

        oncall_user_hash.map { |h| OncallUser.new(h[:user], h[:schedule]) }
      end
    end
  end
end
