# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveDuplicateProjectTagReleases do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:releases) { table(:releases) }

  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:project) { projects.create!(namespace_id: namespace.id, name: 'foo') }
  let(:user) { users.create!(username: 'john.doe', projects_limit: 1) }

  let(:dup_releases) do
    Array.new(4).fill do |i|
      rel = releases.new(project_id: project.id,
                     author_id: user.id,
                     tag: "duplicate tag",
                     released_at: (DateTime.now + i.days))
      rel.save!(validate: false)
      rel
    end
  end

  describe '#up' do
    it "correctly removes duplicate tags from the same project" do
      expect(dup_releases.length).to eq 4
      expect(releases.select(:project_id, :tag, 'MAX(released_at) as max')
                     .group(:project_id, :tag).having('COUNT(*) > 1').length).to eq 1

      migrate!

      expect(releases.select(:project_id, :tag, 'MAX(released_at) as max')
                     .group(:project_id, :tag).having('COUNT(*) > 1').length).to eq 0
    end
  end
end
