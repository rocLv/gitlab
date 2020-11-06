# frozen_string_literal: true

module Gitlab
  module Geo
    # This concern is included on ActiveRecord classes to manage their
    # verification fields. This concern does not handle how verification is
    # performed.
    #
    # This is a separate concern from Gitlab::Geo::ReplicableModel because e.g.
    # MergeRequestDiff stores its verification state in a separate table with
    # the association to MergeRequestDiffDetail.
    module VerificationState
      extend ActiveSupport::Concern
      include ::ShaAttribute
      include Delay
      include Gitlab::Geo::LogHelpers

      VERIFICATION_STATE_VALUES = {
        verification_pending: 0,
        verification_started: 1,
        verification_succeeded: 2,
        verification_failed: 3
      }.freeze
      VERIFICATION_TIMEOUT = 8.hours

      included do
        sha_attribute :verification_checksum

        # rubocop:disable CodeReuse/ActiveRecord
        scope :verification_pending, -> { with_verification_state(:verification_pending) }
        scope :verification_started, -> { with_verification_state(:verification_started) }
        scope :verification_succeeded, -> { with_verification_state(:verification_succeeded) }
        scope :verification_failed, -> { with_verification_state(:verification_failed) }
        scope :checksummed, -> { where.not(verification_checksum: nil) }
        scope :not_checksummed, -> { where(verification_checksum: nil) }
        scope :verification_timed_out, -> { verification_started.where("verification_started_at < ?", VERIFICATION_TIMEOUT.ago) }
        scope :needs_verification, -> { verification_pending.or(verification_failed) }
        # rubocop:enable CodeReuse/ActiveRecord

        state_machine :verification_state, initial: :verification_pending do
          state :verification_pending, value: VERIFICATION_STATE_VALUES[:verification_pending]
          state :verification_started, value: VERIFICATION_STATE_VALUES[:verification_started]
          state :verification_succeeded, value: VERIFICATION_STATE_VALUES[:verification_succeeded] do
            validates :verification_checksum, presence: true
          end
          state :verification_failed, value: VERIFICATION_STATE_VALUES[:verification_failed] do
            validates :verification_failure, presence: true
          end

          before_transition any => :verification_started do |instance, _|
            instance.verification_started_at = Time.current
          end

          before_transition any => :verification_pending do |instance, _|
            instance.verification_retry_count = 0
            instance.verification_retry_at = nil
            instance.verification_failure = nil
          end

          before_transition any => :verification_failed do |instance, _|
            instance.verification_checksum = nil
            instance.verification_retry_count ||= 0
            instance.verification_retry_count += 1
            instance.verification_retry_at = instance.next_retry_time(instance.verification_retry_count)
            instance.verified_at = Time.current
          end

          before_transition any => :verification_succeeded do |instance, _|
            instance.verification_retry_count = 0
            instance.verification_retry_at = nil
            instance.verification_failure = nil
            instance.verified_at = Time.current
          end

          event :verification_started do
            transition [:verification_pending, :verification_started, :verification_succeeded, :verification_failed] => :verification_started
          end

          event :verification_succeeded do
            transition verification_started: :verification_succeeded
          end

          event :verification_failed do
            transition verification_started: :verification_failed
          end

          event :verification_pending do
            transition [:verification_started, :verification_succeeded, :verification_failed] => :verification_pending
          end
        end
      end

      class_methods do
        def verification_state_value(state_string)
          VERIFICATION_STATE_VALUES[state_string]
        end

        # Returns IDs of records that are pending verification.
        #
        # Atomically marks those records "verification_started" in the same DB
        # query.
        #
        def verification_pending_batch(batch_size:)
          relation = verification_pending.order(Gitlab::Database.nulls_first_order(:verified_at)).limit(batch_size) # rubocop:disable CodeReuse/ActiveRecord

          start_verification_batch(relation)
        end

        # Returns IDs of records that failed to verify (calculate and save checksum).
        #
        # Atomically marks those records "verification_started" in the same DB
        # query.
        #
        def verification_failed_batch(batch_size:)
          relation = verification_failed.order(Gitlab::Database.nulls_first_order(:verification_retry_at)).limit(batch_size) # rubocop:disable CodeReuse/ActiveRecord

          start_verification_batch(relation)
        end

        # @return [Integer] number of records that need verification
        def needs_verification_count(limit:)
          needs_verification.limit(limit).count # rubocop:disable CodeReuse/ActiveRecord
        end

        # Atomically marks the records as verification_started, with a
        # verification_started_at time, and returns the primary key of each
        # updated row. This allows VerificationBatchWorker to concurrently get
        # unique batches of primary keys to process.
        #
        # @param [ActiveRecord::Relation] relation with appropriate where, order, and limit defined
        # @return [Array<Integer>] primary key of each updated row
        def start_verification_batch(relation)
          query = start_verification_batch_query(relation)

          # This query performs a write, so we need to wrap it in a transaction
          # to stick to the primary database.
          self.transaction do
            self.connection.execute(query).to_a.map { |row| row[self.primary_key] }
          end
        end

        # Returns a SQL statement which would update all the rows in the
        # relation as verification_started, with a verification_started_at time,
        # and returns the primary key of each updated row.
        #
        # @param [ActiveRecord::Relation] relation with appropriate where, order, and limit defined
        # @return [String] SQL statement which would update all and return primary key of each row
        def start_verification_batch_query(relation)
          started_enum_value = VERIFICATION_STATE_VALUES[:verification_started]

          <<~SQL.squish
            UPDATE #{table_name}
            SET "verification_state" = #{started_enum_value},
              "verification_started_at" = NOW()
            WHERE #{self.primary_key} IN (#{relation.select(self.primary_key).to_sql})
            RETURNING #{self.primary_key}
          SQL
        end
      end

      # Convenience method to update checksum and transition to success state.
      #
      # @param [String] checksum value generated by the checksum routine
      # @param [DateTime] calculation_started_at the moment just before the
      #                   checksum routine was called
      def verification_succeeded_with_checksum!(checksum, calculation_started_at)
        self.verification_checksum = checksum

        self.verification_succeeded!

        if resource_updated_during_checksum?(calculation_started_at)
          # just let backfill pick it up
          self.verification_pending!
        end
      end

      def resource_updated_during_checksum?(calculation_started_at)
        self.reset.verification_started_at > calculation_started_at
      end

      # Convenience method to update failure message and transition to failed
      # state.
      #
      # @param [String] message error information
      # @param [StandardError] error exception
      def verification_failed_with_message!(message, error = nil)
        log_error('Error calculating the checksum', error)

        self.verification_failure = message
        self.verification_failure += ": #{error.message}" if error.respond_to?(:message)

        self.verification_failed!
      end
    end
  end
end
