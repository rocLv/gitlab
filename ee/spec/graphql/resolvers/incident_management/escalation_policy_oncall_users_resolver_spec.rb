# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::IncidentManagement::EscalationPolicyOncallUsersResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let_it_be(:policy) { create(:incident_management_escalation_policy, rule_count: 0, project: project) }

  let_it_be(:oncall_schedule) { create(:incident_management_oncall_schedule, :with_rotation, project: project) }
  let_it_be(:schedule_rule) { create(:incident_management_escalation_rule, oncall_schedule: oncall_schedule, policy: policy) }
  let_it_be(:schedule_rule_user) { schedule_rule.oncall_schedule.rotations.first.users.first }

  let_it_be(:user_only_rule) { create(:incident_management_escalation_rule, :with_user, policy: policy) }
  let_it_be(:user_rule_user) { user_only_rule.user }

  let(:args) { {} }
  let(:resolver) { described_class }

  subject(:resolved_users) { sync(resolve_oncall_users(args, current_user: current_user).to_a) }

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
    project.add_reporter(current_user)
  end

  it 'returns objects with user and schedule attributes' do
    expect(resolved_users.length).to eq(2)
    expect(resolved_users).to all be_a(Struct).and respond_to(:user, :schedule)

    expect(resolved_users).to match_array([
      have_attributes(user: schedule_rule_user, schedule: oncall_schedule),
      have_attributes(user: user_rule_user, schedule: nil)
    ])
  end

  context 'when user does not have permissions' do
    let(:another_user) { create(:user) }

    subject(:resolved_users) { sync(resolve_oncall_users(args, current_user: another_user).to_a) }

    it 'raises ResourceNotAvailable error' do
      expect { resolved_users }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

  private

  def resolve_oncall_users(args = {}, context = { current_user: current_user })
    resolve(resolver, obj: policy, args: args, ctx: context)
  end
end
