# frozen_string_literal: true

module EE
  module NamespaceSetting
    extend ActiveSupport::Concern

    prepended do
      before_create :set_default_delayed_project_removal
    end

    delegate :root_ancestor, to: :namespace

    def prevent_forking_outside_group?
      saml_setting = root_ancestor.saml_provider&.prohibited_outer_forks?

      return saml_setting unless namespace.feature_available?(:group_forking_protection)

      saml_setting || root_ancestor.namespace_settings&.prevent_forking_outside_group
    end

    private

    def set_default_delayed_project_removal
      if self[:delayed_project_removal].nil? && namespace.root? && ::Gitlab::CurrentSettings.deletion_adjourned_period.nonzero?
        self.delayed_project_removal = true
      end
    end
  end
end
