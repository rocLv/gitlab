# frozen_string_literal: true

class AddApiCheckEnforcedToSamlProviders < Gitlab::Database::Migration[1.0]
  def change
    add_column :saml_providers, :api_check_enforced, :boolean, default: false, null: false
  end
end
