# frozen_string_literal: true

class AddDeletedInfoToDesign < Gitlab::Database::Migration[1.0]
  def change
    add_column :design_management_designs, :deleted_at, :datetime_with_timezone
  end
end
