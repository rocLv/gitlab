# frozen_string_literal: true

class DropTablesCiBuildTraceSection < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database::SchemaHelpers

  disable_ddl_transaction!

  FUNCTION_NAME = 'trigger_91dc388a5fe6'

  def up
    with_lock_retries do
      drop_table :ci_build_trace_sections
      drop_table :ci_build_trace_section_names
    end

    drop_function(FUNCTION_NAME)
  end

  def down
    with_lock_retries do
      create_table :ci_build_trace_section_names, id: :serial, force: :cascade do |t|
        t.integer "project_id", null: false
        t.string "name", null: false
        t.index %w[project_id name], name: "index_ci_build_trace_section_names_on_project_id_and_name", unique: true
      end

      create_table :ci_build_trace_sections, id: false, primary_key: [:build_id, :section_name_id], force: :cascade do |t|
        t.integer "project_id", null: false
        t.datetime "date_start", null: false # rubocop:disable Migration/Datetime
        t.datetime "date_end", null: false # rubocop:disable Migration/Datetime
        t.bigint "byte_start", null: false
        t.bigint "byte_end", null: false
        t.integer "build_id", null: false
        t.integer "section_name_id", null: false
        t.index ["project_id"], name: "index_ci_build_trace_sections_on_project_id"
        t.index ["section_name_id"], name: "index_ci_build_trace_sections_on_section_name_id"
      end
    end

    execute "ALTER TABLE ci_build_trace_sections ADD CONSTRAINT ci_build_trace_sections_pkey PRIMARY KEY (build_id, section_name_id)"

    add_concurrent_foreign_key :ci_build_trace_sections, :ci_build_trace_section_names, column: :section_name_id, on_delete: :cascade
    add_concurrent_foreign_key :ci_build_trace_sections, :projects, column: :project_id, on_delete: :cascade
    add_concurrent_foreign_key :ci_build_trace_sections, :ci_builds, column: :build_id, on_delete: :cascade
    add_concurrent_foreign_key :ci_build_trace_section_names, :projects, column: :project_id, on_delete: :cascade

    # Creates build_id_convert_to_bigint column while ensuring relevant trigger and function are also created
    initialize_conversion_of_integer_to_bigint(:ci_build_trace_sections, :build_id, primary_key: :build_id)
  end
end
