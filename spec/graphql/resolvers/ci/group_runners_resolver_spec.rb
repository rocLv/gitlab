# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::GroupRunnersResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let(:args) { }

    subject { resolve(described_class, obj: obj, ctx: { current_user: user }, args: args) }

    shared_context 'resolve args with membership' do
      let(:membership) { nil }
      let(:args) do
        { membership: membership }.reject { |_, v| v.nil? }
      end
    end

    context 'with a RunnersFinder double' do
      let_it_be(:user) { build(:user) }

      let(:finder) { instance_double(::Ci::RunnersFinder) }
      let(:expected_params) { :uninitialized }

      before do
        allow(::Ci::RunnersFinder).to receive(:new).with(current_user: user, params: expected_params).once.and_return(finder)
        allow(finder).to receive(:execute).once.and_return([:execute_return_value])
      end

      shared_examples 'a resolver delegating to RunnersFinder' do
        it 'calls new RunnersFinder instance with expected parameters' do
          is_expected.to be_an_instance_of(Gitlab::Graphql::Pagination::ArrayConnection)
          expect(finder).to have_received(:execute).once
        end

        it 'returns the result from RunnersFinder.execute' do
          expect(subject.items.to_a).to eq([:execute_return_value])
        end
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

      context 'with obj set to group' do
        let(:obj) { build(:group) }

        context 'with a membership argument' do
          include_context 'resolve args with membership'

          context 'set to :direct' do
            let(:membership) { :direct }
            let(:expected_params) { a_hash_including(membership: membership) }

            it_behaves_like 'a resolver delegating to RunnersFinder'
          end

          context 'not set' do
            let(:membership) { }
            let(:expected_params) { a_hash_including(membership: nil) }

            it_behaves_like 'a resolver delegating to RunnersFinder'
          end

          context 'set to :descendants' do
            let(:membership) { :descendants }
            let(:expected_params) { a_hash_including(membership: :descendants) }

            it_behaves_like 'a resolver delegating to RunnersFinder'
          end
        end

        context 'when status is filtered' do
          let(:args) do
            { status: 'active' }
          end

          let(:expected_params) { a_hash_including(status_status: 'active') }

          it_behaves_like 'a resolver delegating to RunnersFinder'
        end

        context 'when tag list is filtered' do
          let(:args) do
            { tag_list: %w(project_runner,active_runner) }
          end

          let(:expected_params) { a_hash_including(tag_name: %w(project_runner,active_runner)) }

          it_behaves_like 'a resolver delegating to RunnersFinder'
        end

        context 'when text is filtered' do
          let(:args) do
            { search: 'abc' }
          end

          let(:expected_params) { a_hash_including(search: 'abc') }

          it_behaves_like 'a resolver delegating to RunnersFinder'
        end
      end

      context 'with obj set to unsupported value' do
        let_it_be(:obj) { build(:project) }

        it 'raises error' do
          expect { subject }.to raise_error('Expected group missing')
        end
      end
    end

    context 'with a real RunnersFinder instance' do
      include_context 'runners resolver setup'

      context 'with obj set to group' do
        let(:obj) { group }

        context 'with user as group owner' do
          before do
            group.add_owner(user)
          end

          context 'with empty args' do
            let(:args) do
              {}
            end

            context 'when the user cannot see runners' do
              let(:user) { build(:user) }

              it 'returns no runners' do
                expect(subject.items.to_a).to be_empty
              end
            end

            context 'without sort' do
              it 'returns all the runners' do
                expect(subject.items.to_a).to contain_exactly(inactive_project_runner, offline_project_runner, group_runner, subgroup_runner)
              end
            end
          end

          context 'with a sort argument' do
            context "set to :contacted_asc" do
              let(:args) do
                { sort: :contacted_asc }
              end

              it { expect(subject.items.to_a).to eq([offline_project_runner, inactive_project_runner, group_runner, subgroup_runner]) }
            end
          end

          context 'when type is filtered' do
            let(:args) do
              { type: runner_type.to_s }
            end

            context 'to instance runners' do
              let(:runner_type) { :instance_type }

              it 'returns empty array' do
                expect(subject.items.to_a).to eq([])
              end
            end

            context 'to group runners' do
              let(:runner_type) { :group_type }

              it 'returns the group runner' do
                expect(subject.items.to_a).to contain_exactly(group_runner, subgroup_runner)
              end
            end
          end
        end

        context 'when user has no access to the group' do
          context 'with a membership argument' do
            include_context 'resolve args with membership'

            let(:membership) { :descendants }

            it { expect(subject.items.to_a).to eq([]) }
          end
        end
      end
    end
  end
end
