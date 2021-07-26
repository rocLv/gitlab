# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Billings routing' do
  let_it_be(:group) { create(:group) }

  describe 'Seat usage' do
    it "routes to seat_usage#show" do
      expect(get("/groups/#{group.path}/-/seat_usage")).to route_to('groups/seat_usage#show', group_id: group.path)
    end

    it "routes to seat_usage#export" do
      expect(post("/groups/#{group.path}/-/seat_usage/export")).to route_to('groups/seat_usage#export', group_id: group.path)
    end
  end
end
