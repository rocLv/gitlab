# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module DuplicateJobs
      module Strategies
        module DeduplicatesWhenScheduling
          def initialize(duplicate_job)
            @duplicate_job = duplicate_job
          end

          def schedule(job)
            if deduplicatable_job? && check! && duplicate_job.duplicate?
              job['duplicate-of'] = duplicate_job.existing_jid

              if duplicate_job.idempotent?
                duplicate_job.update_latest_wal_location! if preserve_wal_location?

                Gitlab::SidekiqLogging::DeduplicationLogger.instance.log(
                  job, "dropped #{strategy_name}", duplicate_job.options)
                return false
              end
            end

            yield
          end

          def perform(job)
            update_job_wal_location!(job)

            yield
          end

          private

          def update_job_wal_location!(job)
            return unless preserve_wal_location? && duplicate_job.latest_wal_locations.present?

            job['dedup_wal_locations'] = duplicate_job.latest_wal_locations
          end

          def preserve_wal_location?
            Feature.enabled?(:preserve_latest_wal_locations_for_idempotent_jobs, default_enabled: :yaml)
          end

          def deduplicatable_job?
            !duplicate_job.scheduled? || duplicate_job.options[:including_scheduled]
          end

          def check!
            duplicate_job.check!(expiry)
          end

          def expiry
            return DuplicateJob::DUPLICATE_KEY_TTL unless duplicate_job.scheduled?

            time_diff = duplicate_job.scheduled_at.to_i - Time.now.to_i

            time_diff > 0 ? time_diff : DuplicateJob::DUPLICATE_KEY_TTL
          end
        end
      end
    end
  end
end
