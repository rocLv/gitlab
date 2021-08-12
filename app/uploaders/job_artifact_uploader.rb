# frozen_string_literal: true

class JobArtifactUploader < GitlabUploader
  extend Workhorse::UploadPath
  include ObjectStorage::Concern

  UnknownFileLocationError = Class.new(StandardError)

  storage_options Gitlab.config.artifacts

  alias_method :upload, :model

  def cached_size
    return model.size if model.size.present? && !model.file_changed?

    size
  end

  def store_dir
    dynamic_segment
  end

  private

  def dynamic_segment
    if model.hashed_persistence_agnostic_path?
      hashed_persistence_agnostic_path
    elsif model.hashed_path?
      hashed_path
    elsif model.legacy_path?
      legacy_path
    else
      raise UnknownFileLocationError
    end
  end

  # Allows file to be stored prior to model being saved, in order to avoid long transactions
  def hashed_persistence_agnostic_path
    Gitlab::HashedPath.new(model.job_id, root_hash: model.project_id)
  end

  def hashed_path
    Gitlab::HashedPath.new(model.created_at.utc.strftime('%Y_%m_%d'), model.job_id, model.id, root_hash: model.project_id)
  end

  def legacy_path
    File.join(model.created_at.utc.strftime('%Y_%m'), model.project_id.to_s, model.job_id.to_s)
  end
end
