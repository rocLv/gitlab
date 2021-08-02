# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProtectedEnvironment do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:deploy_access_levels) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:deploy_access_levels) }
  end

  describe '#accessible_to?' do
    let(:project) { create(:project) }
    let(:environment) { create(:environment, project: project) }
    let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }
    let(:user) { create(:user) }

    subject { protected_environment.accessible_to?(user) }

    context 'when user is admin' do
      let(:user) { create(:user, :admin) }

      it { is_expected.to be_truthy }
    end

    context 'when access has been granted to user' do
      before do
        create_deploy_access_level(protected_environment, user: user)
      end

      it { is_expected.to be_truthy }
    end

    context 'when specific access has been assigned to a group' do
      let(:group) { create(:group) }

      before do
        create_deploy_access_level(protected_environment, group: group)
      end

      it 'allows members of the group' do
        group.add_developer(user)

        expect(subject).to be_truthy
      end

      it 'rejects non-members of the group' do
        expect(subject).to be_falsy
      end
    end

    context 'when access has been granted to maintainers' do
      before do
        create_deploy_access_level(protected_environment, access_level: Gitlab::Access::MAINTAINER)
      end

      it 'allows maintainers' do
        project.add_maintainer(user)

        expect(subject).to be_truthy
      end

      it 'rejects developers' do
        project.add_developer(user)

        expect(subject).to be_falsy
      end
    end

    context 'when access has been granted to developers' do
      before do
        create_deploy_access_level(protected_environment, access_level: Gitlab::Access::DEVELOPER)
      end

      it 'allows maintainers' do
        project.add_maintainer(user)

        expect(subject).to be_truthy
      end

      it 'allows developers' do
        project.add_developer(user)

        expect(subject).to be_truthy
      end
    end
  end

  describe '.sorted_by_name' do
    subject(:protected_environments) { described_class.sorted_by_name }

    it "sorts protected environments by name" do
      %w(staging production development).each {|name| create(:protected_environment, name: name)}

      expect(protected_environments.map(&:name)).to eq %w(development production staging)
    end
  end

  describe '.with_environment_id' do
    subject(:protected_environments) { described_class.with_environment_id }

    it "sets corresponding environment id if there is environment matching by name and project" do
      project = create(:project)
      environment = create(:environment, project: project, name: 'production')

      production = create(:protected_environment, project: project, name: 'production')
      removed_environment = create(:protected_environment, project: project, name: 'removed environment')

      expect(protected_environments).to match_array [production, removed_environment]
      expect(protected_environments.find {|e| e.name == 'production'}.environment_id).to eq environment.id
      expect(protected_environments.find {|e| e.name == 'removed environment'}.environment_id).to be_nil
    end
  end

  describe '.deploy_access_levels_by_user' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:environment) { create(:environment, project: project, name: 'production') }
    let(:protected_environment) { create(:protected_environment, project: project, name: 'production') }
    let(:deploy_access_level_for_user) { create_deploy_access_level(protected_environment, user: user) }

    before do
      create_deploy_access_level(protected_environment, user: create(:user))
      create_deploy_access_level(protected_environment, group: create(:group))
    end

    it 'returns matching deploy access levels for the given user' do
      expect(described_class.deploy_access_levels_by_user(user))
        .to contain_exactly(deploy_access_level_for_user)
    end

    context 'when user is assigned to protected environment in the other project' do
      let(:other_project) { create(:project) }
      let(:other_protected_environment) { create(:protected_environment, project: other_project, name: 'production') }
      let(:other_deploy_access_level_for_user) { create_deploy_access_level(other_protected_environment, user: user) }

      it 'returns matching deploy access levels for the given user in the specific project' do
        expect(project.protected_environments.deploy_access_levels_by_user(user))
          .to contain_exactly(deploy_access_level_for_user)
        expect(other_project.protected_environments.deploy_access_levels_by_user(user))
          .to contain_exactly(other_deploy_access_level_for_user)
      end
    end
  end

  describe '.deploy_access_levels_by_group' do
    let(:group) { create(:group) }
    let(:project) { create(:project) }
    let(:environment) { create(:environment, project: project, name: 'production') }
    let(:protected_environment) { create(:protected_environment, project: project, name: 'production') }
    let(:deploy_access_level_for_group) { create_deploy_access_level(protected_environment, group: group) }

    it 'returns matching deploy access levels for the given group' do
      _deploy_access_level_for_different_group = create_deploy_access_level(protected_environment, group: create(:group))
      _deploy_access_level_for_user = create_deploy_access_level(protected_environment, user: create(:user))

      expect(described_class.deploy_access_levels_by_group(group))
        .to contain_exactly(deploy_access_level_for_group)
    end

    context 'when user is assigned to protected environment in the other project' do
      let(:other_project) { create(:project) }
      let(:other_protected_environment) { create(:protected_environment, project: other_project, name: 'production') }
      let(:other_deploy_access_level_for_group) { create_deploy_access_level(other_protected_environment, group: group) }

      it 'returns matching deploy access levels for the given group in the specific project' do
        expect(project.protected_environments.deploy_access_levels_by_group(group))
          .to contain_exactly(deploy_access_level_for_group)
        expect(other_project.protected_environments.deploy_access_levels_by_group(group))
          .to contain_exactly(other_deploy_access_level_for_group)
      end
    end
  end

  describe '.for_environment' do
    let_it_be(:project, reload: true) { create(:project) }
    let_it_be(:environment) { build(:environment, name: 'production', project: project) }
    let_it_be(:protected_environment) { create(:protected_environment, name: 'production', project: project) }

    subject { described_class.for_environment(environment) }

    it { is_expected.to eq([protected_environment]) }

    it 'caches result', :request_store do
      described_class.for_environment(environment).to_a

      expect { described_class.for_environment(environment).to_a }
        .not_to exceed_query_limit(0)
    end

    context 'when environment is a different name' do
      let_it_be(:environment) { build(:environment, name: 'staging', project: project) }

      it { is_expected.to be_empty }
    end

    context 'when environment exists in a different project' do
      let_it_be(:environment) { build(:environment, name: 'production', project: create(:project)) }

      it { is_expected.to be_empty }
    end

    context 'when environment does not exist' do
      let(:environment) { }

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  def create_deploy_access_level(protected_environment, **opts)
    protected_environment.deploy_access_levels.create(**opts)
  end
end
