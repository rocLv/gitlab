# frozen_string_literal: true

###
# API endpoints for the RubyGem package registry
module API
  class RubygemPackages < ::API::Base
    include ::API::Helpers::Authentication
    helpers ::API::Helpers::PackagesHelpers

    feature_category :package_registry

    # The Marshal version can be found by "#{Marshal::MAJOR_VERSION}.#{Marshal::MINOR_VERSION}"
    # Updating the version should require a GitLab API version change.
    MARSHAL_VERSION = '4.8'
    PACKAGE_FILENAME = 'package.gem'
    FILE_NAME_REQUIREMENTS = {
      file_name: API::NO_SLASH_URL_PART_REGEX
    }.freeze

    content_type :binary, 'application/octet-stream'

    authenticate_with do |accept|
      accept.token_types(:personal_access_token, :deploy_token, :job_token)
            .sent_through(:http_token)
    end

    before do
      require_packages_enabled!
      authenticate!
      not_found! unless Feature.enabled?(:rubygem_packages, user_project)
    end

    params do
      requires :id, type: String, desc: 'The ID or full path of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/packages/rubygems' do
        desc 'Download the spec index file' do
          detail 'This feature was introduced in GitLab 13.9'
        end
        params do
          requires :file_name, type: String, desc: 'Spec file name'
        end
        get ":file_name", requirements: FILE_NAME_REQUIREMENTS do
          # To be implemented in https://gitlab.com/gitlab-org/gitlab/-/issues/299267
          not_found!
        end

        desc 'Download the gemspec file' do
          detail 'This feature was introduced in GitLab 13.9'
        end
        params do
          requires :file_name, type: String, desc: 'Gemspec file name'
        end
        get "quick/Marshal.#{MARSHAL_VERSION}/:file_name", requirements: FILE_NAME_REQUIREMENTS do
          # To be implemented in https://gitlab.com/gitlab-org/gitlab/-/issues/299284
          not_found!
        end

        desc 'Download the .gem package' do
          detail 'This feature was introduced in GitLab 13.9'
        end
        params do
          requires :file_name, type: String, desc: 'Package file name'
        end
        get "gems/:file_name", requirements: FILE_NAME_REQUIREMENTS do
          # To be implemented in https://gitlab.com/gitlab-org/gitlab/-/issues/299283
          not_found!
        end

        namespace 'api/v1' do
          desc 'Authorize a gem upload from workhorse' do
            detail 'This feature was introduced in GitLab 13.9'
          end
          post 'gems/authorize' do
            authorize_workhorse!(
              subject: user_project,
              has_length: false,
              maximum_size: user_project.actual_limits.rubygems_max_file_size
            )
          end

          desc 'Upload a gem' do
            detail 'This feature was introduced in GitLab 13.9'
          end
          params do
            requires :file, type: ::API::Validations::Types::WorkhorseFile, desc: 'The package file to be published (generated by Multipart middleware)'
          end
          post 'gems' do
            authorize_upload!(user_project)
            bad_request!('File is too large') if user_project.actual_limits.exceeded?(:rubygems_max_file_size, params[:file].size)

            track_package_event('push_package', :rubygems)

            ActiveRecord::Base.transaction do
              package = ::Packages::CreateTemporaryPackageService.new(
                user_project, current_user, declared_params.merge(build: current_authenticated_job)
              ).execute(:rubygems, name: ::Packages::Rubygems::TEMPORARY_PACKAGE_NAME)

              file_params = {
                file:      params[:file],
                file_name: PACKAGE_FILENAME
              }

              ::Packages::CreatePackageFileService.new(
                package, file_params.merge(build: current_authenticated_job)
              ).execute
            end

            created!
          rescue ObjectStorage::RemoteStoreError => e
            Gitlab::ErrorTracking.track_exception(e, extra: { file_name: params[:file_name], project_id: user_project.id })

            forbidden!
          end

          desc 'Fetch a list of dependencies' do
            detail 'This feature was introduced in GitLab 13.9'
          end
          params do
            optional :gems, type: String, desc: 'Comma delimited gem names'
          end
          get 'dependencies' do
            # To be implemented in https://gitlab.com/gitlab-org/gitlab/-/issues/299282
            not_found!
          end
        end
      end
    end
  end
end
