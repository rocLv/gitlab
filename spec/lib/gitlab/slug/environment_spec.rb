# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Slug::Environment do
  describe '#generate' do
    {
      "staging-12345678901234567" => "staging-123456789",
      "9-staging-123456789012345" => "env-9-staging-123",
      "staging-1234567890123456"  => "staging-123456789",
      "staging-1234567890123456-" => "staging-123456789",
      "production"                => "production",
      "PRODUCTION"                => "production",
      "review/1-foo"              => "review-1-foo",
      "1-foo"                     => "env-1-foo",
      "1/foo"                     => "env-1-foo",
      "foo-"                      => "foo",
      "foo--bar"                  => "foo-bar",
      "foo**bar"                  => "foo-bar",
      "*-foo"                     => "env-foo",
      "staging-12345678-"         => "staging-12345678",
      "staging-12345678-01234567" => "staging-12345678",
      ""                          => "env",
      nil                         => "env"
    }.each do |name, expected|
      it "returns a slug matching #{expected}-[a-z0-9]{6}, given #{name}" do
        slug = described_class.new(name).generate

        expect(slug).to match(/\A#{expected}-[a-z0-9]{6}\z/)
      end
    end
  end
end
