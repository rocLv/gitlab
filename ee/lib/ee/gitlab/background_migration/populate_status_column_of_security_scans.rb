# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      # Backgroung migration to populate the latest column of `security_scans` records
      module PopulateStatusColumnOfSecurityScans
        UPDATE_BATCH_SIZE = 500
        UPDATE_SQL = <<~SQL
          UPDATE
            security_scans
          SET
            status = (
              CASE
                WHEN ci_builds.status = 'success' THEN 1
                ELSE 2
              END
            )
          FROM
            ci_builds
          WHERE
            ci_builds.id = security_scans.build_id AND
            security_scans.id BETWEEN %<start_id>d AND %<end_id>d
        SQL

        def perform(start_id, end_id)
          log_info('Migration has been started', start_id: start_id, end_id: end_id)

          (start_id..end_id).step(UPDATE_BATCH_SIZE).each do |batch_start|
            update_batch(batch_start)
          end

          log_info('Migration has been finished', start_id: start_id, end_id: end_id)
        end

        private

        delegate :connection, to: ActiveRecord::Base, private: true
        delegate :execute, :quote, to: :connection, private: true

        def update_batch(batch_start)
          sql = format(UPDATE_SQL, start_id: quote(batch_start), end_id: quote(batch_start + UPDATE_BATCH_SIZE - 1))
          result = execute(sql)

          log_info('Records have been updated', count: result.cmd_tuples)
        end

        def log_info(message, extra = {})
          log_payload = extra.merge(migrator: self.class.name, message: message)

          ::Gitlab::BackgroundMigration::Logger.info(**log_payload)
        end
      end
    end
  end
end
