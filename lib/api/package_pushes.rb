# frozen_string_literal: true

module API
  class PackagePushes < ::API::Base
    feature_category :package_registry

    resource :package_pushes, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Download package file from single push' do
        detail 'This feature is WIP'
      end
      params do
        requires :pipeline_id, type: String, desc: 'Pipeline id of package push'
      end
      route_setting :authentication, job_token_allowed: true
      get ':pipeline_id' do
        push = ::Packages::Push.with_pipeline_id(params[:pipeline_id]).last

        not_found!("Package push") unless can?(current_user, :read_package, push&.project)

        present_carrierwave_file!(push.package_file.file, supports_direct_download: false)
      end
    end
  end
end
