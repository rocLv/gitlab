# frozen_string_literal: true

module EE
  module Awardable
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    private

    override :lock_and_update_upvotes_count
    def lock_and_update_upvotes_count
      super

      maintain_elasticsearch_update if maintaining_elasticsearch?
    end
  end
end
