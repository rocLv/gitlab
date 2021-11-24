# frozen_string_literal: true

module Geo
  class JobArtifactState < ApplicationRecord
    include EachBatch

    self.primary_key = :job_artifact_id

    belongs_to :job_artifact, inverse_of: :job_artifact_state, class_name: 'Ci::JobArtifact'
  end
end
