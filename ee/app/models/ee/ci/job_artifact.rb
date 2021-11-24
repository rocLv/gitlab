# frozen_string_literal: true

module EE
  # CI::JobArtifact EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Ci::JobArtifact` model
  module Ci::JobArtifact
    include ::Gitlab::Utils::StrongMemoize
    extend ActiveSupport::Concern

    SECURITY_REPORT_FILE_TYPES = %w[sast secret_detection dependency_scanning container_scanning cluster_image_scanning dast coverage_fuzzing api_fuzzing].freeze

    prepended do
      include ::Gitlab::Geo::ReplicableModel
      include ::Gitlab::Geo::VerificationState

      with_replicator ::Geo::JobArtifactReplicator

      has_one :job_artifact_state, autosave: false, inverse_of: :job_artifact, class_name: '::Geo::JobArtifactState'

      # After destroy callbacks are often skipped because of FastDestroyAll.
      # All destroy callbacks should be implemented in `Ci::JobArtifacts::DestroyBatchService`
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/297472
      after_commit :log_geo_deleted_event, on: :destroy

      LICENSE_SCANNING_REPORT_FILE_TYPES = %w[license_scanning].freeze
      DEPENDENCY_LIST_REPORT_FILE_TYPES = %w[dependency_scanning].freeze
      METRICS_REPORT_FILE_TYPES = %w[metrics].freeze
      CONTAINER_SCANNING_REPORT_TYPES = %w[container_scanning].freeze
      CLUSTER_IMAGE_SCANNING_REPORT_TYPES = %w[cluster_image_scanning].freeze
      DAST_REPORT_TYPES = %w[dast].freeze
      REQUIREMENTS_REPORT_FILE_TYPES = %w[requirements].freeze
      COVERAGE_FUZZING_REPORT_TYPES = %w[coverage_fuzzing].freeze
      API_FUZZING_REPORT_TYPES = %w[api_fuzzing].freeze
      BROWSER_PERFORMANCE_REPORT_FILE_TYPES = %w[browser_performance performance].freeze

      scope :security_reports, -> (file_types: SECURITY_REPORT_FILE_TYPES) do
        requested_file_types = *file_types

        with_file_types(requested_file_types & SECURITY_REPORT_FILE_TYPES)
      end

      scope :license_scanning_reports, -> do
        with_file_types(LICENSE_SCANNING_REPORT_FILE_TYPES)
      end

      scope :dependency_list_reports, -> do
        with_file_types(DEPENDENCY_LIST_REPORT_FILE_TYPES)
      end

      scope :container_scanning_reports, -> do
        with_file_types(CONTAINER_SCANNING_REPORT_TYPES)
      end

      scope :cluster_image_scanning_reports, -> do
        with_file_types(CLUSTER_IMAGE_SCANNING_REPORT_TYPES)
      end

      scope :dast_reports, -> do
        with_file_types(DAST_REPORT_TYPES)
      end

      scope :metrics_reports, -> do
        with_file_types(METRICS_REPORT_FILE_TYPES)
      end

      scope :coverage_fuzzing_reports, -> do
        with_file_types(COVERAGE_FUZZING_REPORT_TYPES)
      end

      scope :api_fuzzing_reports, -> do
        with_file_types(API_FUZZING_REPORT_TYPES)
      end

      scope :with_files_stored_locally, -> { where(file_store: ::ObjectStorage::Store::LOCAL) }
      scope :with_files_stored_remotely, -> { where(file_store: ::ObjectStorage::Store::REMOTE) }
      scope :with_verification_state, ->(state) { joins(:job_artifact_state).where(job_artifact_states: { verification_state: verification_state_value(state) }) }
      scope :checksummed, -> { joins(:job_artifact_state).where.not(job_artifact_states: { verification_checksum: nil } ) }
      scope :not_checksummed, -> { joins(:job_artifact_state).where(job_artifact_states: { verification_checksum: nil } ) }
      scope :available_verifiables, -> { joins(:job_artifact_state) }

      delegate :validate_schema?, to: :job

      delegate :verification_retry_at, :verification_retry_at=,
               :verified_at, :verified_at=,
               :verification_checksum, :verification_checksum=,
               :verification_failure, :verification_failure=,
               :verification_retry_count, :verification_retry_count=,
               :verification_state=, :verification_state,
               :verification_started_at=, :verification_started_at,
               to: :job_artifact_state

      after_save :save_verification_details
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      override :associated_file_types_for
      def associated_file_types_for(file_type)
        return LICENSE_SCANNING_REPORT_FILE_TYPES if LICENSE_SCANNING_REPORT_FILE_TYPES.include?(file_type)
        return BROWSER_PERFORMANCE_REPORT_FILE_TYPES if BROWSER_PERFORMANCE_REPORT_FILE_TYPES.include?(file_type)

        super
      end

      # @param primary_key_in [Range, CoolWidget] arg to pass to primary_key_in scope
      # @return [ActiveRecord::Relation<CoolWidget>] everything that should be synced to this node, restricted by primary key
      def self.replicables_for_current_secondary(primary_key_in)
        # This issue template does not help you write this method.
        #
        # This method is called only on Geo secondary sites. It is called when
        # we want to know which records to replicate. This is not easy to automate
        # because for example:
        #
        # * The "selective sync" feature allows admins to choose which namespaces #   to replicate, per secondary site. Most Models are scoped to a
        #   namespace, but the nature of the relationship to a namespace varies
        #   between Models.
        # * The "selective sync" feature allows admins to choose which shards to
        #   replicate, per secondary site. Repositories are associated with
        #   shards. Most blob types are not, but Project Uploads are.
        # * Remote stored replicables are not replicated, by default. But the
        #   setting `sync_object_storage` enables replication of remote stored
        #   replicables.
        #
        # Search the codebase for examples, and consult a Geo expert if needed.
      end

      override :verification_state_table_class
      def verification_state_table_class
        ::Geo::JobArtifactState
      end
    end

    def job_artifact_state
      super || build_job_artifact_state
    end

    def verification_state_object
      job_artifact_state
    end

    def log_geo_deleted_event
      ::Geo::JobArtifactDeletedEventStore.new(self).create!
    end

    # Ideally we would have a method to return an instance of
    # parsed report regardless of the `file_type` but this will
    # require more effort so we can have this security reports
    # specific method here for now.
    def security_report(validate: false)
      strong_memoize(:security_report) do
        next unless file_type.in?(SECURITY_REPORT_FILE_TYPES)

        signatures_enabled = project.licensed_feature_available?(:vulnerability_finding_signatures)

        report = ::Gitlab::Ci::Reports::Security::Report.new(file_type, job.pipeline, nil).tap do |report|
          each_blob do |blob|
            ::Gitlab::Ci::Parsers.fabricate!(file_type, blob, report, signatures_enabled, validate: (validate && validate_schema?)).parse!
          end
        rescue StandardError
          report.add_error('ParsingError')
        end

        # This will remove the duplicated findings within the artifact itself
        ::Security::MergeReportsService.new(report).execute
      end
    end

    # This method is necessary to remove the reference to the
    # security report object which allows GC to free the memory
    # slots in vm_heap occupied for the report object and it's
    # dependents.
    def clear_security_report
      clear_memoization(:security_report)
    end
  end
end
