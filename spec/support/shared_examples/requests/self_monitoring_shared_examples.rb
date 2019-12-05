# frozen_string_literal: true

RSpec.shared_examples 'not accessible if feature flag is disabled' do
  before do
    stub_feature_flags(self_monitoring_project: false)
  end

  it 'returns not_implemented' do
    subject

    aggregate_failures do
      expect(response).to have_gitlab_http_status(:not_implemented)
      expect(json_response).to eq(
        'message' => _('Self-monitoring is not enabled on this GitLab server, contact your administrator.'),
        'documentation_url' => help_page_path('administration/monitoring/gitlab_instance_administration_project/index')
      )
    end
  end
end

RSpec.shared_examples 'handles missing or invalid job_id' do |job_id_param|
  it "returns bad_request for #{job_id_param}" do
    get status_create_self_monitoring_project_admin_application_settings_path, params: job_id_param

    aggregate_failures do
      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response).to eq('message' => '"job_id" must be an alphanumeric value')
    end
  end
end

RSpec.shared_examples 'not accessible to non-admin users' do
  context 'with unauthenticated user' do
    it 'redirects to signin page' do
      subject

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'with authenticated non-admin user' do
    before do
      login_as(create(:user))
    end

    it 'returns status not_found' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
