# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class ProjectImportedFromGithub < Resource::Project
      attribute :github_repo_id

      def fabricate!
        self.import = true

        Page::Main::Menu.perform(&:go_to_create_project)

        Page::Project::New.perform do |project_page|
          project_page.click_import_project
          project_page.click_github_link
        end

        Page::Project::Import::Github.perform do |import_page|
          import_page.add_personal_access_token(github_personal_access_token)
          import_page.import!(github_repository_path, name)
        end
      end

      def fabricate_via_api!
        super
      rescue ResourceURLMissingError
        "#{Runtime::Scenario.gitlab_address}/#{group.full_path}/#{name}"
      end

      def api_post_path
        '/import/github'
      end

      def api_post_body
        {
          repo_id: github_repo_id,
          new_name: name,
          target_namespace: group.full_path,
          personal_access_token: github_personal_access_token,
          ci_cd_only: false
        }
      end

      def transform_api_resource(api_resource)
        api_resource
      end
    end
  end
end
