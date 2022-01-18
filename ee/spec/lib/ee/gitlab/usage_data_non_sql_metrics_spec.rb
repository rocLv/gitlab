# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataNonSqlMetrics do
  include UsageDataHelpers

  before do
    stub_usage_data_connections
    stub_database_flavor_check
  end

  describe '.uncached_data' do
    it 'does make instrumentations_class DB calls' do
      recorder = ActiveRecord::QueryRecorder.new do
        described_class.uncached_data
      end

      expect(recorder.count).to eq(65)
    end
  end
end
