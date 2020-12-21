module Geo
  class LfsObjectReplicator < Gitlab::Geo::Replicator
    include ::Geo::BlobReplicatorStrategy

    def carrierwave_uploader
      model_record.file
    end

    def self.model
      ::LfsObject
    end

    def self.replication_enabled_by_default?
      true
    end
  end
end
