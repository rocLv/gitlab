# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::GroupRunnersResolver do
  include GraphqlHelpers

  include_context 'runners resolver setup'

  it_behaves_like Resolvers::Ci::RunnersResolver

  shared_context 'resolve args with membership' do
    let(:membership) { nil }
    let(:args) do
      { membership: membership }.reject { |_, v| v.nil? }
    end
  end

  describe '#resolve' do
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

      context 'with obj set to group' do
        let(:obj) { group }

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
