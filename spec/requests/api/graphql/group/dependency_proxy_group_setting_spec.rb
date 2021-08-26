# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'getting dependency proxy settings for a group' do
  using RSpec::Parameterized::TableSyntax
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }

  let(:dependency_proxy_group_setting_fields) do
    <<~GQL
      #{all_graphql_fields_for('dependency_proxy_setting'.classify, max_depth: 1)}
    GQL
  end

  let(:fields) do
    <<~GQL
      #{query_graphql_field('dependency_proxy_setting', {}, dependency_proxy_group_setting_fields)}
    GQL
  end

  let(:query) do
    graphql_query_for(
      'group',
      { 'fullPath' => group.full_path },
      fields
    )
  end

  let(:variables) { {} }
  let(:dependency_proxy_group_setting_response) { graphql_data.dig('group', 'dependencyProxySetting') }

  before do
    stub_config(dependency_proxy: { enabled: true })
    group.create_dependency_proxy_setting!(enabled: true)
  end

  subject { post_graphql(query, current_user: user, variables: variables) }

  it_behaves_like 'a working graphql query' do
    before do
      subject
    end
  end

  context 'with different permissions' do
    where(:group_visibility, :role, :access_granted) do
      :private | :maintainer | true
      :private | :developer  | true
      :private | :reporter   | true
      :private | :guest      | true
      :private | :anonymous  | false
      :public  | :maintainer | true
      :public  | :developer  | true
      :public  | :reporter   | true
      :public  | :guest      | true
      :public  | :anonymous  | false
    end

    with_them do
      before do
        group.update_column(:visibility_level, Gitlab::VisibilityLevel.const_get(group_visibility.to_s.upcase, false))
        group.add_user(user, role) unless role == :anonymous
      end

      it 'return the proper response' do
        subject

        if access_granted
          expect(dependency_proxy_group_setting_response).to eq('enabled' => true)
        else
          expect(dependency_proxy_group_setting_response).to be_blank
        end
      end
    end
  end
end