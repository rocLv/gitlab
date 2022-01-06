# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveDuplicateProjectTagReleases do
  let_it_be(:user)    { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:releases) {
    Array.new(4).fill do |i|
      build(:release, project: project, author: user, tag: "duplicate tag", released_at: DateTime.now() + i.days).save(validate: false)
    end
  }

  describe '#up' do
    it "correctly removes duplicate tags from the same project" do
      expect(Release.select(:project_id, :tag, 'MAX(released_at) as max').group(:project_id, :tag).having('COUNT(*) > 1').length).to eq 1

      migrate!

      expect(Release.select(:project_id, :tag, 'MAX(released_at) as max').group(:project_id, :tag).having('COUNT(*) > 1').length).to eq 0
    end
  end
end
