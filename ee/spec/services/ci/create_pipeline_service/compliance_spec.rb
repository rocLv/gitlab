# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService do
  include AfterNextHelpers

  subject(:execute) { service.execute(:push) }

  let_it_be(:project) { create(:project, :repository, name: 'website') }
  let_it_be(:compliance_group) { create(:group, :private, name: "compliance") }
  let_it_be(:compliance_project) { create(:project, :repository, namespace: compliance_group, name: "hippa") }
  let_it_be(:framework) { create(:compliance_framework, namespace_id: compliance_group.id, pipeline_configuration_full_path: ".compliance-gitlab-ci.yml@compliance/hippa") }
  let_it_be(:framework_project_setting) { create(:compliance_framework_project_setting, project: project, framework_id: framework.id) }
  let_it_be(:merge_request) do
    create(
      :merge_request,
      source_project: project,
      source_branch: 'feature',
      target_project: project,
      target_branch: 'master'
    )
  end

  let(:user) { project.owner }
  let(:ref) { 'refs/heads/feature' }
  let(:project_ref_sha) { project.commit(ref).sha }
  let(:compliance_project_ref_sha) { compliance_project.commit('HEAD').sha }
  let(:compliance_config) do
    <<~EOY
    ---
    compliance_build:
      stage: build
      script:
        - echo 'hello from compliance build'
    compliance_test:
      stage: test
      script:
        - echo 'hello from compliance test'

    include:
      - project: '$CI_PROJECT_PATH'
        file: '$CI_CONFIG_PATH'
        ref: '$CI_COMMIT_SHA'
    EOY
  end

  let(:project_config) do
    <<~EOY
    ---
    project_build:
      stage: build
      script:
        - echo 'hello from project build'
    EOY
  end

  let(:service) { described_class.new(project, user, { ref: ref }) }

  before do
    stub_feature_flags(ff_evaluate_group_level_compliance_pipeline: true)
    stub_licensed_features(evaluate_group_level_compliance_pipeline: true)

    # allow_next(Repository).to receive(:blob_data_at).and_return(compliance_config)
    # allow(project.repository).to receive(:blob_data_at)
    #   .with(project_ref_sha, '.gitlab_ci.yaml')
    #   .and_return(project_config)

    allow_next_instance_of(Repository) do |repository|
      allow(repository).to receive(:blob_data_at).with(an_instance_of(String), ".compliance-gitlab-ci.yml")
        .and_return(compliance_config)

      allow(repository).to receive(:blob_data_at).with(project_ref_sha, '.gitlab-ci.yml')
        .and_return(project_config)
    end
  end

  context 'when user has access to compliance project' do
    before do
      compliance_project.add_maintainer(project.owner)
    end

    it 'persists pipeline' do
      expect(execute.payload).to be_persisted
    end

    it 'sets the correct source' do
      expect(execute.payload.config_source).to eq("compliance_source")
    end

    it 'persists jobs' do
      expect { execute }.to change(Ci::Build, :count).from(0).to(3)
    end

    it do
      expect(execute.payload.processables.map(&:name)).to contain_exactly(
        'compliance_build', 'compliance_test', 'project_build'
      )
    end
  end

  context 'when user does not have access to compliance project' do
    it 'includes access denied error' do
      expect(execute.payload.yaml_errors).to eq "Project `compliance/hippa` not found or access denied!"
    end

    it 'does not persist jobs' do
      expect { execute }.not_to change(Ci::Build, :count).from(0)
    end
  end
end
