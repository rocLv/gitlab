# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module SecurityCompliance
        class Menu < ::Sidebars::Menu
          override :configure_menu_items
          def configure_menu_items
            add_item(MenuItems::Configuration.new(context))
          end

          override :link
          def link
            project_security_configuration_path(context.project)
          end

          override :extra_container_html_options
          def extra_container_html_options
            {
              data: { qa_selector: 'security_configuration_link' }
            }
          end

          override :render?
          def render?
            can?(context.current_user, :access_security_and_compliance, context.project) &&
              can?(context.current_user, :read_security_configuration, context.project)
          end

          override :title
          def title
            _('Security & Compliance')
          end

          override :sprite_icon
          def sprite_icon
            'shield'
          end
        end
      end
    end
  end
end

Sidebars::Projects::Menus::SecurityCompliance::Menu.prepend_if_ee('EE::Sidebars::Projects::Menus::SecurityCompliance::Menu')
