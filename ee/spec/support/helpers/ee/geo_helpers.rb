# frozen_string_literal: true

module EE
  module GeoHelpers
    def stub_current_geo_node(node)
      allow(::Gitlab::Geo).to receive(:current_node).and_return(node)

      # GeoNode.current? returns true only when the node is passed
      # otherwise it returns false
      allow(GeoNode).to receive(:current?).and_return(false)
      allow(GeoNode).to receive(:current?).with(node).and_return(true)
    end

    def stub_current_node_name(name)
      allow(GeoNode).to receive(:current_node_name).and_return(name)
    end

    def stub_primary_node
      allow(::Gitlab::Geo).to receive(:primary?).and_return(true)
      allow(::Gitlab::Geo).to receive(:secondary?).and_return(false)
    end

    def stub_secondary_node
      allow(::Gitlab::Geo).to receive(:primary?).and_return(false)
      allow(::Gitlab::Geo).to receive(:secondary?).and_return(true)
    end

    def create_project_on_shard(shard_name)
      project = create(:project)

      # skipping validation which requires the shard name to exist in Gitlab.config.repositories.storages.keys
      project.update_column(:repository_storage, shard_name)

      project
    end

    def registry_factory_name(registry_class)
      registry_class.underscore.tr('/', '_').to_sym
    end

    def with_no_geo_database_configured(&block)
      allow(::Gitlab::Geo).to receive(:geo_database_configured?).and_return(false)

      yield

      # We need to unstub here or the DatabaseCleaner will have issues since it
      # will appear as though the tracking DB were not available
      allow(::Gitlab::Geo).to receive(:geo_database_configured?).and_call_original
    end

    def stub_dummy_replicator_class(model_class: 'DummyModel')
      stub_const('Geo::DummyReplicator', Class.new(::Gitlab::Geo::Replicator))

      ::Geo::DummyReplicator.class_eval do
        event :test
        event :another_test

        def self.model
          model_class.constantize
        end

        def handle_after_create_commit
          true
        end

        def handle_after_checksum_succeeded
          true
        end

        protected

        def consume_event_test(user:, other:)
          true
        end
      end
    end

    def stub_dummy_model_class
      stub_const('DummyModel', Class.new(ApplicationRecord))

      DummyModel.class_eval do
        include ::Geo::ReplicableModel
        include ::Geo::VerifiableModel

        with_replicator Geo::DummyReplicator

        def self.replicables_for_current_secondary(primary_key_in)
          self.primary_key_in(primary_key_in)
        end
      end

      DummyModel.reset_column_information
    end

    # Example:
    #
    # before(:all) do
    #   create_dummy_model_table
    # end
    #
    # after(:all) do
    #   drop_dummy_model_table
    # end
    def create_dummy_model_table
      ActiveRecord::Schema.define do
        create_table :dummy_models, force: true do |t|
          t.binary :verification_checksum
          t.integer :verification_state
          t.datetime_with_timezone :verification_started_at
          t.datetime_with_timezone :verified_at
          t.datetime_with_timezone :verification_retry_at
          t.integer :verification_retry_count
          t.text :verification_failure
        end
      end
    end

    def drop_dummy_model_table
      ActiveRecord::Schema.define do
        drop_table :dummy_models, force: true
      end
    end

    # Example:
    #
    # before(:all) do
    #   create_dummy_model_with_separate_state_table
    # end

    # after(:all) do
    #   drop_dummy_model_with_separate_state_table
    # end

    # before do
    #   stub_dummy_model_with_separate_state_class
    # end

    def create_dummy_model_with_separate_state_table
      ActiveRecord::Schema.define do
        create_table :_test_dummy_model_with_separate_states, force: true
      end

      ActiveRecord::Schema.define do
        create_table :_test_dummy_model_states, id: false, force: true do |t|
          t.bigint :_test_dummy_model_with_separate_state_id
          t.binary :verification_checksum
          t.integer :verification_state
          t.datetime_with_timezone :verification_started_at
          t.datetime_with_timezone :verified_at
          t.datetime_with_timezone :verification_retry_at
          t.integer :verification_retry_count
          t.text :verification_failure
        end
      end
    end

    def drop_dummy_model_with_separate_state_table
      ActiveRecord::Schema.define do
        drop_table :_test_dummy_model_with_separate_states, force: true
      end

      ActiveRecord::Schema.define do
        drop_table :_test_dummy_model_states, force: true
      end
    end

    def stub_dummy_model_with_separate_state_class
      stub_const('TestDummyModelWithSeparateState', Class.new(ApplicationRecord))

      TestDummyModelWithSeparateState.class_eval do
        self.table_name = '_test_dummy_model_with_separate_states'

        include ::Geo::ReplicableModel
        include ::Geo::VerifiableModel

        with_replicator Geo::DummyReplicator

        has_one :_test_dummy_model_state,
          autosave: false,
          inverse_of: :_test_dummy_model_with_separate_state,
          foreign_key: :_test_dummy_model_with_separate_state_id

        after_save :save_verification_details

        delegate :verification_retry_at, :verification_retry_at=,
                 :verified_at, :verified_at=,
                 :verification_checksum, :verification_checksum=,
                 :verification_failure, :verification_failure=,
                 :verification_retry_count, :verification_retry_count=,
                 :verification_state=, :verification_state,
                 :verification_started_at=, :verification_started_at,
          to: :_test_dummy_model_state, allow_nil: true

        scope :available_verifiables, -> { joins(:_test_dummy_model_state) }

        def verification_state_object
          _test_dummy_model_state
        end

        def self.replicables_for_current_secondary(primary_key_in)
          self.primary_key_in(primary_key_in)
        end

        def self.verification_state_table_class
          TestDummyModelState
        end

        private

        def _test_dummy_model_state
          super || build__test_dummy_model_state
        end
      end

      TestDummyModelWithSeparateState.reset_column_information

      stub_const('TestDummyModelState', Class.new(ApplicationRecord))

      TestDummyModelState.class_eval do
        include EachBatch

        self.table_name = '_test_dummy_model_states'
        self.primary_key = '_test_dummy_model_with_separate_state_id'

        belongs_to :_test_dummy_model_with_separate_state, inverse_of: :_test_dummy_model_state
      end

      TestDummyModelState.reset_column_information
    end
  end
end
