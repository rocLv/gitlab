# frozen_string_literal: true

class AddEncryptedStaticObjectsExternalStorageAuthToken < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_column :application_settings, :static_objects_external_storage_auth_token_encrypted, :text
    add_text_limit :application_settings, :static_objects_external_storage_auth_token_encrypted, 255
  end

  def down
    remove_text_limit :application_settings, :static_objects_external_storage_auth_token_encrypted
    remove_column :application_settings, :static_objects_external_storage_auth_token_encrypted
  end
end
