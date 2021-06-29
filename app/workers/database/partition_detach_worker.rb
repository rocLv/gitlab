# frozen_string_literal: true

module Database
  class PartitionDetachWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :database
    idempotent!

    def perform
      Gitlab::Database::Partitioning::PartitionManager.new.detach_partitions
    ensure
      Gitlab::Database::Partitioning::PartitionMonitoring.new.report_metrics
    end
  end
end
