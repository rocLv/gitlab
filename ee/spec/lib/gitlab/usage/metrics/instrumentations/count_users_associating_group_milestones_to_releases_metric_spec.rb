# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountUsersAssociatingGroupMilestonesToReleasesMetric do
  before do
    stub_licensed_features(group_milestone_project_releases: true)
    group = create(:group)

    create(:release, :with_milestones, created_at: 3.days.ago)

    project = create(:project, group: group)
    group_milestone = create(:milestone, group: group)

    release = create(:release, project: project, created_at: 3.days.ago)
    release.milestones << group_milestone
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: '28d', data_source: 'database' } do
    let(:expected_value) { 1 }
  end
end
