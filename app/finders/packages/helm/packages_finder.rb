# frozen_string_literal: true

module Packages
  module Helm
    class PackagesFinder
      include ::Packages::FinderHelper

      MAX_PACKAGES_COUNT = 300

      def initialize(project, channel)
        @project = project
        @channel = channel
      end

      def execute
        packages_for_project(@project)
          .helm
          .has_version
          .with_helm_channel(@channel)
      end
    end
  end
end
