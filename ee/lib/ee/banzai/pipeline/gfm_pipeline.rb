# frozen_string_literal: true

module EE
  module Banzai
    module Pipeline
      module GfmPipeline
        extend ActiveSupport::Concern

        class_methods do
          def metrics_filters
            [
              ::Banzai::Filter::InlineAlertMetricsFilter,
              *super
            ]
          end

          def reference_filters
            [
              ::Banzai::Filter::EpicReferenceFilter,
              ::Banzai::Filter::DesignReferenceFilter,
              *super
            ]
          end

          def metrics_filters
            [
              ::Banzai::Filter::InlineClusterMetricsFilter,
              *super
            ]
          end
        end
      end
    end
  end
end
