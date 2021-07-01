# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'creating escalation policy' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:schedule) { create(:incident_management_oncall_schedule, project: project) }

  let(:params) do
    {
      projectPath: project.full_path,
      name: 'Escalation Policy 1',
      description: 'Description',
      rules: [
        {
          oncallScheduleIid: schedule.iid,
          elapsedTimeSeconds: 60,
          status: 'ACKNOWLEDGED'
        }
      ]
    }
  end

  let(:mutation) do
    graphql_mutation(:escalation_policy_create, params) do
      <<-QL.strip_heredoc
        escalationPolicy {
          id
          name
          description
          rules {
            status
            elapsedTimeSeconds
            user {
              id
              username
            }
            oncallSchedule {
              name
              iid
            }
          }
        }
        errors
      QL
    end
  end

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
    stub_feature_flags(escalation_policies_mvc: project)
    project.add_maintainer(current_user)
  end

  subject(:resolve) { post_graphql_mutation(mutation, current_user: current_user) }

  it 'successfully creates the policy and rules' do
    resolve

    expect(mutation_response['errors']).to be_empty

    escalation_policy_response = mutation_response['escalationPolicy']
    expect(escalation_policy_response['name']).to eq(params[:name])
    expect(escalation_policy_response['description']).to eq(params[:description])
    expect(escalation_policy_response['rules'].size).to eq(params[:rules].size)

    first_rule = escalation_policy_response['rules'].first
    expect(first_rule['status']).to eq('ACKNOWLEDGED')
    expect(first_rule['elapsedTimeSeconds']).to eq(params.dig(:rules, 0, :elapsedTimeSeconds))
    expect(first_rule['status']).to eq(params.dig(:rules, 0, :status))
  end

  context 'rule has a user' do
    let_it_be(:user_for_rule) { create(:user) }

    before do
      params[:rules][0].delete(:oncallScheduleIid)
      params[:rules][0][:username] = user_for_rule.username
    end

    # it_behaves_like 'returns a GraphQL error', 'A user has insufficient permissions to access the project'

    context 'user has permission' do
      before do
        project.add_reporter(user_for_rule)
      end

      it 'returns the escalation policy with no errors' do
        resolve

        expect(mutation_response['errors']).to be_empty

        escalation_policy_response = mutation_response['escalationPolicy']

        first_rule = escalation_policy_response['rules'].first
        expect(first_rule['user']['username']).to eq(params.dig(:rules, 0, :username))
      end
    end
  end

  include_examples 'correctly reorders escalation rule inputs' do
    let(:variables) { params }
  end

  context 'errors' do
    context 'user does not have permission' do
      subject(:resolve) { post_graphql_mutation(mutation, current_user: create(:user)) }

      it 'raises an error' do
        resolve

        expect_graphql_errors_to_include("The resource that you are attempting to access does not exist or you don't have permission to perform this action")
      end
    end

    context 'no rules given' do
      before do
        params[:rules] = []
      end

      it 'raises an error' do
        resolve

        expect(mutation_response['errors'][0]).to eq('Escalation policies must have at least one rule')
      end
    end

    context 'feature flag disabled' do
      before do
        stub_feature_flags(escalation_policies_mvc: false)
      end

      it 'raises an error' do
        resolve

        expect_graphql_errors_to_include('Escalation policies are not supported for this project')
      end
    end
  end

  def mutation_response
    graphql_mutation_response(:escalation_policy_create)
  end
end
