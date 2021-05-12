# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CodeQualityDegradation'] do
  it do
    expect(described_class).to have_graphql_fields(
      :description,
      :fingerprint,
      :severity,
      :path,
      :line
    )
  end
end
