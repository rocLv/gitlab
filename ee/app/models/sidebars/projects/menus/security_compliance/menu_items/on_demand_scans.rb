# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module SecurityCompliance
        module MenuItems
          class OnDemandScans < ::Sidebars::MenuItem
            override :link
            def link
              new_project_on_demand_scan_path(context.project)
            end

            override :extra_container_html_options
            def extra_container_html_options
              {
                data: { qa_selector: 'on_demand_scans_link' }
              }
            end

            override :active_routes
            def active_routes
              { path: %w[
                  projects/on_demand_scans#index
                  projects/on_demand_scans#new
                  projects/on_demand_scans#edit
                ] }
            end

            override :title
            def title
              s_('OnDemandScans|On-demand Scans')
            end

            override :render?
            def render?
              can?(context.current_user, :read_on_demand_scans, context.project)
            end
          end
        end
      end
    end
  end
end
