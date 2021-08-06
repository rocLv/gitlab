# frozen_string_literal: true

# This service is responsible for creating a pipeline for a package
# push.

module Packages
  class CreatePushService
    include ::Gitlab::Utils::StrongMemoize

    def initialize(package_file, current_user)
      @package_file = package_file
      @current_user = current_user
    end

    def execute
      return unless @package_file && @current_user

      ::Packages::Push.create!(
        package_file: @package_file,
        pipeline: create_pipeline
      )
    end

    private

    def create_pipeline
      Ci::CreatePipelineService.new(
        project,
        @current_user,
        ref: branch,
        sha: commit
      ).execute(:package_push_event).payload
    end

    def project
      strong_memoize(:project) do
        @package_file.project
      end
    end

    def branch
      strong_memoize(:branch) do
        project.default_branch
      end
    end

    def commit
      project.commit(branch)&.id if branch
    end
  end
end
