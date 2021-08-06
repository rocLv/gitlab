# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreatePackagesPushes < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'uniq_packages_pushes_on_sha'

  def up
    unless table_exists?(:packages_pushes)
      create_table :packages_pushes do |t|
        t.references :package_file,
                     foreign_key: { to_table: :packages_package_files, on_delete: :cascade },
                     null: false,
                     index: true
        t.references :pipeline,
                     foreign_key: { to_table: :ci_pipelines, on_delete: :cascade },
                     null: false,
                     index: true
        t.timestamps_with_timezone
      end
    end
  end

  def down
    drop_table(:packages_pushes)
  end
end
