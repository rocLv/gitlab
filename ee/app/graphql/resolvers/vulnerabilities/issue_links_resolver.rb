# frozen_string_literal: true

module Resolvers
  module Vulnerabilities
    class IssueLinksResolver < BaseResolver
      type Types::Vulnerability::IssueLinkType, null: true

      argument :link_type, Types::Vulnerability::IssueLinkTypeEnum,
               required: false,
               description: 'Filter issue links by link type'

      delegate :issue_links, :created_issue_links, to: :object, private: true

      def resolve(link_type: nil, **)
        issue_links_by_link_type(link_type)
      end

      private

      def issue_links_by_link_type(link_type)
        case link_type.to_s.downcase
        when Types::Vulnerability::IssueLinkTypeEnum.enum['created']
          created_issue_links
        else
          issue_links.by_link_type(link_type)
        end
      end
    end
  end
end
