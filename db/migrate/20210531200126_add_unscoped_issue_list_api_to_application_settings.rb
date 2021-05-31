# frozen_string_literal: true

class AddUnscopedIssueListApiToApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :application_settings, :unscoped_issue_list_api, :boolean, null: false, default: true
    end
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :unscoped_issue_list_api
    end
  end
end
