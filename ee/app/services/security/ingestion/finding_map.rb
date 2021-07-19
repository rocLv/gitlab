# frozen_string_literal: true

module Security
  module Ingestion
    # This entity is used in ingestion services to
    # map security_finding - report_finding - vulnerability_id - finding_id
    #
    # You can think this as the Message object in the pipeline design pattern
    # which is passed between tasks.
    class FindingMap
      FINDING_ATTRIBUTES = %i[confidence metadata_version name raw_metadata report_type severity details].freeze
      RAW_METADATA_ATTRIBUTES = %w[description message solution cve location].freeze

      attr_reader :security_finding, :report_finding
      attr_accessor :finding_id, :vulnerability_id, :new_record, :identifier_ids

      delegate :uuid, to: :security_finding

      def initialize(security_finding, report_finding)
        @security_finding = security_finding
        @report_finding = report_finding
        @identifier_ids = []
      end

      def identifiers
        @identifiers ||= report_finding.identifiers.first(Vulnerabilities::Finding::MAX_NUMBER_OF_IDENTIFIERS)
      end

      def set_identifier_ids_by(fingerprint_id_map)
        @identifier_ids = identifiers.map(&:fingerprint).map { |fingerprint| fingerprint_id_map[fingerprint] }
      end

      def to_hash
        # This is horrible! We should address this with a follow-up
        parsed_from_raw_metadata = Gitlab::Json.parse(report_finding.raw_metadata).slice(*RAW_METADATA_ATTRIBUTES).symbolize_keys

        report_finding.to_hash
                      .slice(*FINDING_ATTRIBUTES)
                      .merge(parsed_from_raw_metadata)
                      .merge(primary_identifier_id: identifier_ids.first, location_fingerprint: report_finding.location.fingerprint, project_fingerprint: report_finding.project_fingerprint)
                      .merge(uuid: security_finding.uuid, scanner_id: security_finding.scanner_id)
      end
    end
  end
end
