# frozen_string_literal: true

class RemoveDuplicateProjectTagReleases < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    Release.select(:project_id, :tag, 'MAX(released_at) as max').group(:project_id, :tag).having('COUNT(*) > 1').each do |rel|
      Release.where(project_id: rel.project_id, tag: rel.tag).where("released_at < ?", rel.max).delete_all
    end
  end

  def down
    # no-op
    #
    # releases with the same tag within a project have been removed
    # and therefore the duplicate release data is no longer available
  end
end
