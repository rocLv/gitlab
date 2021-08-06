# frozen_string_literal: true

# This service is responsible for creating a pipeline for a package
# push.

module Packages
  class CreatePipelineService < BaseContainerService
    include ::Gitlab::Utils::StrongMemoize

    alias_method :push, :container

    def execute
      return unless push

      create_pipeline_for(push)
    end

    private

    def create_pipeline_for(push)
      # TODO: [package ci pipeline] A package push never references a git sha.
      # The Push model was created to simulate one but we have still
      # mandatory properties refering to a repository such as "ref".
      Ci::CreatePipelineService.new(
        project,
        current_user,
        ref: branch,
        sha: commit
      ).execute(:package_push_event)
    end

    def project
      push.project
    end

    def branch
      strong_memoize(:branch) { project.default_branch }
    end

    def commit
      strong_memoize(:commit) do
        project.commit(branch)&.id if branch
      end
    end
  end
end
