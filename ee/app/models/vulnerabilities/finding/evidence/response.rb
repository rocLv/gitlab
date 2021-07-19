# frozen_string_literal: true

module Vulnerabilities
  class Finding
    class Evidence
      class Response < ApplicationRecord
        include WithBody

        self.table_name = 'vulnerability_finding_evidence_responses'

        FIELD_NAMES = %w[reason_phrase].freeze

        belongs_to :evidence,
                   class_name: 'Vulnerabilities::Finding::Evidence',
                   inverse_of: :response,
                   foreign_key: 'vulnerability_finding_evidence_id',
                   optional: true
        belongs_to :supporting_message,
                   class_name: 'Vulnerabilities::Finding::Evidence::SupportingMessage',
                   inverse_of: :response,
                   foreign_key: 'vulnerability_finding_evidence_supporting_message_id',
                   optional: true

        has_many :headers,
                 class_name: 'Vulnerabilities::Finding::Evidence::Header',
                 inverse_of: :response,
                 foreign_key: 'vulnerability_finding_evidence_response_id'

        accepts_nested_attributes_for :headers

        validates :reason_phrase, length: { maximum: 2048 }, presence: true
      end
    end
  end
end
