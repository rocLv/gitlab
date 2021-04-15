# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module SecurityCompliance
        module MenuItems
          class Dashboard < ::Sidebars::MenuItem
            override :link
            def link
              project_security_dashboard_index_path(context.project)
            end

            override :extra_container_html_options
            def extra_container_html_options
              {
                data: { qa_selector: 'security_dashboard_link' }
              }
            end

            override :active_routes
            def active_routes
              { path: 'projects/security/dashboard#index' }
            end

            override :title
            def title
              _('Security Dashboard')
            end

            override :render?
            def render?
              can?(context.current_user, :read_project_security_dashboard, context.project)
            end
          end
        end
      end
    end
  end
end
