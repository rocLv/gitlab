# frozen_string_literal: true

class AddGroupFeaturesTable < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    unless table_exists?(:group_features)
      with_lock_retries do
        create_table :group_features do |t|
          t.references :group, index: { unique: true }, foreign_key: { to_table: :namespaces, on_delete: :cascade }, null: false
          t.timestamps_with_timezone null: false
          t.integer :wiki_access_level, default: 20, null: false
        end
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :group_features
    end
  end
end
