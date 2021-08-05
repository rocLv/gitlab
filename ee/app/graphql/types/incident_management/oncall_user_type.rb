# frozen_string_literal: true

module Types
  module IncidentManagement
    # rubocop: disable Graphql/AuthorizeTypes
    class OncallUserType < BaseObject
      graphql_name 'IncidentManagementOncallUser'
      description 'Described an oncall user'

      field :schedule,
            ::Types::IncidentManagement::OncallScheduleType,
            null: true,
            description: 'Schedule where the user is on call.'

      field :user,
            ::Types::UserType,
            null: false,
            description: 'User that is on call.'
    end
  end
end
