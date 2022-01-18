# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SecurityFeaturesHelper do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group, refind: true) { create(:group) }
  let_it_be(:user, refind: true) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
    allow(helper).to receive(:can?).and_return(false)
  end

  describe '#group_level_security_dashboard_available?' do
    where(:group_level_compliance_dashboard_enabled, :read_group_compliance_dashboard_permission, :result) do
      false | false | false
      true  | false | false
      false | true  | false
      true  | true  | true
    end

    with_them do
      before do
        stub_licensed_features(group_level_compliance_dashboard: group_level_compliance_dashboard_enabled)
        allow(helper).to receive(:can?).with(user, :read_group_compliance_dashboard, group).and_return(read_group_compliance_dashboard_permission)
      end

      it 'returns the expected result' do
        expect(helper.group_level_compliance_dashboard_available?(group)).to eq(result)
      end
    end
  end

  describe '#group_level_credentials_inventory_available?' do
    where(:credentials_inventory_feature_enabled, :enforced_group_managed_accounts, :read_group_credentials_inventory_permission, :result) do
      true  | false | false | false
      true  | true  | false | false
      true  | false | true  | false
      true  | true  | true  | true
      false | false | false | false
      false | false | false | false
      false | false | true  | false
      false | true  | true  | false
    end

    with_them do
      before do
        stub_licensed_features(credentials_inventory: credentials_inventory_feature_enabled)
        allow(group).to receive(:enforced_group_managed_accounts?).and_return(enforced_group_managed_accounts)
        allow(helper).to receive(:can?).with(user, :read_group_credentials_inventory, group).and_return(read_group_credentials_inventory_permission)
      end

      it 'returns the expected result' do
        expect(helper.group_level_credentials_inventory_available?(group)).to eq(result)
      end
    end
  end

  describe '#group_level_security_dashboard_data' do
    subject { helper.group_level_security_dashboard_data(group) }

    before do
      allow(helper).to receive(:current_user).and_return(:user)
      allow(helper).to receive(:can?).and_return(true)
    end

    let(:expected_data) do
      {
        projects_endpoint: "http://localhost/api/v4/groups/#{group.id}/projects",
        group_full_path: group.full_path,
        no_vulnerabilities_svg_path: helper.image_path('illustrations/issues.svg'),
        empty_state_svg_path: helper.image_path('illustrations/security-dashboard-empty-state.svg'),
        sbom_survey_svg_path: helper.image_path('illustrations/monitoring/tracing.svg'),
        operational_empty_state_svg_path: helper.image_path('illustrations/security-dashboard_empty.svg'),
        operational_help_path: help_page_path('user/application_security/policies/index'),
        survey_request_svg_path: helper.image_path('illustrations/security-dashboard_empty.svg'),
        dashboard_documentation: help_page_path('user/application_security/security_dashboard/index'),
        false_positive_doc_url: help_page_path('user/application_security/vulnerabilities/index'),
        vulnerabilities_export_endpoint: "/api/v4/security/groups/#{group.id}/vulnerability_exports",
        scanners: '[]',
        can_admin_vulnerability: 'true',
        can_view_false_positive: 'false',
        has_projects: 'false'
      }
    end

    it { is_expected.to eq(expected_data) }
  end

  describe '#group_security_discover_data' do
    let_it_be(:group) { create(:group) }

    let(:variant) { :control }
    let(:content) { 'discover-group-security' }
    let(:expected_group_security_discover_data) do
      {
        group: {
          id: group.id,
          name: group.name
        },
        link: {
          main: new_trial_registration_path(glm_source: 'gitlab.com', glm_content: content),
          secondary: group_billings_path(group.root_ancestor, source: content),
          feedback: 'https://gitlab.com/gitlab-org/growth/ui-ux/issues/25'
        }
      }.merge(helper.hand_raise_props(group.root_ancestor))
    end

    subject(:group_security_discover_data) do
      helper.group_security_discover_data(group)
    end

    before do
      stub_experiments(pql_three_cta_test: variant)
    end

    it 'builds correct hash' do
      expect(group_security_discover_data).to eq(expected_group_security_discover_data)
    end

    context 'candidate for pql_three_cta_test' do
      let(:variant) { :candidate }
      let(:content) { 'discover-group-security-pqltest' }

      it 'renders a hash with pqltest content' do
        expect(group_security_discover_data).to eq(expected_group_security_discover_data)
      end
    end
  end
end
