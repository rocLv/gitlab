# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::GroupRunnersResolver do
  include GraphqlHelpers

  include_context 'runners resolver setup'

  shared_context 'resolve args with membership' do
    let(:membership) { nil }
    let(:args) do
      { membership: membership }.reject { |_, v| v.nil? }
    end
  end

  describe '#resolve' do
    let(:args) { }

    subject { resolve(described_class, obj: obj, ctx: { current_user: user }, args: args).items.to_a }

    context 'with user as group owner' do
      before do
        group.add_owner(user)
      end

      context 'with obj set to nil' do
        let(:obj) { nil }

        context 'with a membership argument' do
          include_context 'resolve args with membership'

          context 'set to :direct' do
            let(:membership) { :direct }

            it 'raises an error' do
              expect { subject }.to raise_error('Expected group missing')
            end
          end
        end
      end

      context 'with obj set to subgroup' do
        let(:obj) { subgroup }

        context 'with a membership argument' do
          include_context 'resolve args with membership'

          context 'set to :direct' do
            let(:membership) { :direct }

            it { is_expected.to contain_exactly(subgroup_runner) }
          end

          context 'not set' do
            it { is_expected.to contain_exactly(subgroup_runner) }
          end

          context 'set to :descendants' do
            let(:membership) { :descendants }

            it { is_expected.to contain_exactly(subgroup_runner) }
          end
        end
      end

      context 'with obj set to unsupported value' do
        let_it_be(:obj) { build(:project) }

        it 'raises error' do
          expect { subject }.to raise_error('Expected group missing')
        end
      end

      context 'with obj set to group' do
        let(:obj) { group }

        context 'with empty args' do
          let(:args) do
            {}
          end

          context 'when the user cannot see runners' do
            let(:user) { build(:user) }

            it 'returns no runners' do
              is_expected.to be_empty
            end
          end

          context 'without sort' do
            it 'returns all the runners' do
              is_expected.to contain_exactly(inactive_project_runner, offline_project_runner, group_runner, subgroup_runner)
            end
          end
        end

        context 'with a sort argument' do
          context "set to :contacted_asc" do
            let(:args) do
              { sort: :contacted_asc }
            end

            it { is_expected.to eq([offline_project_runner, inactive_project_runner, group_runner, subgroup_runner]) }
          end

          context "set to :contacted_desc" do
            let(:args) do
              { sort: :contacted_desc }
            end

            it { is_expected.to eq([offline_project_runner, inactive_project_runner, group_runner, subgroup_runner].reverse) }
          end

          context "set to :created_at_desc" do
            let(:args) do
              { sort: :created_at_desc }
            end

            it { is_expected.to eq([subgroup_runner, group_runner, offline_project_runner, inactive_project_runner]) }
          end

          context "set to :created_at_asc" do
            let(:args) do
              { sort: :created_at_asc }
            end

            it { is_expected.to eq([subgroup_runner, group_runner, offline_project_runner, inactive_project_runner].reverse) }
          end
        end

        context 'when type is filtered' do
          let(:args) do
            { type: runner_type.to_s }
          end

          context 'to instance runners' do
            let(:runner_type) { :instance_type }

            it 'returns empty array' do
              is_expected.to eq([])
            end
          end

          context 'to group runners' do
            let(:runner_type) { :group_type }

            it 'returns the group runner' do
              is_expected.to contain_exactly(group_runner, subgroup_runner)
            end
          end

          context 'to project runners' do
            let(:runner_type) { :project_type }

            it 'returns the project runner' do
              is_expected.to contain_exactly(inactive_project_runner, offline_project_runner)
            end
          end
        end

        context 'when status is filtered' do
          let(:args) do
            { status: runner_status.to_s }
          end

          context 'to active runners' do
            let(:runner_status) { :active }

            it 'returns the instance and group runners' do
              is_expected.to contain_exactly(offline_project_runner, group_runner, subgroup_runner)
            end
          end

          context 'to offline runners' do
            let(:runner_status) { :offline }

            it 'returns the offline project runner' do
              is_expected.to contain_exactly(offline_project_runner)
            end
          end
        end

        context 'when tag list is filtered' do
          let(:args) do
            { tag_list: tag_list }
          end

          context 'with "project_runner" tag' do
            let(:tag_list) { ['project_runner'] }

            it 'returns the project_runner runners' do
              is_expected.to contain_exactly(offline_project_runner, inactive_project_runner)
            end
          end

          context 'with "project_runner" and "active_runner" tags as comma-separated string' do
            let(:tag_list) { ['project_runner,active_runner'] }

            it 'returns the offline_project_runner runner' do
              is_expected.to contain_exactly(offline_project_runner)
            end
          end

          context 'with "active_runner" and "project_runner" tags as array' do
            let(:tag_list) { %w[project_runner active_runner] }

            it 'returns the offline_project_runner runner' do
              is_expected.to contain_exactly(offline_project_runner)
            end
          end
        end

        context 'when text is filtered' do
          let(:args) do
            { search: search_term }
          end

          context 'to "project"' do
            let(:search_term) { 'project' }

            it 'returns both project runners' do
              is_expected.to contain_exactly(inactive_project_runner, offline_project_runner)
            end
          end

          context 'to "group"' do
            let(:search_term) { 'group' }

            it 'returns group runners' do
              is_expected.to contain_exactly(group_runner, subgroup_runner)
            end
          end

          context 'to "defghi"' do
            let(:search_term) { 'defghi' }

            it 'returns runners containing term in token' do
              is_expected.to contain_exactly(offline_project_runner)
            end
          end
        end

        context 'with a membership argument' do
          include_context 'resolve args with membership'

          shared_examples 'returns self and descendant runners' do
            it { is_expected.to contain_exactly(group_runner, subgroup_runner, offline_project_runner, inactive_project_runner) }
          end

          context 'set to :direct' do
            let(:membership) { :direct }

            it { is_expected.to contain_exactly(group_runner) }
          end

          context 'not set' do
            include_examples 'returns self and descendant runners'
          end

          context 'set to :descendants' do
            let(:membership) { :descendants }

            include_examples 'returns self and descendant runners'
          end
        end
      end
    end

    context 'when user has no access to the group' do
      context 'with obj set to subgroup' do
        let(:obj) { subgroup }

        context 'with a membership argument' do
          include_context 'resolve args with membership'

          context 'set to :direct' do
            let(:membership) { :direct }

            it { is_expected.to eq([]) }
          end

          context 'set to :descendants' do
            let(:membership) { :descendants }

            it { is_expected.to eq([]) }
          end
        end
      end
    end
  end
end
