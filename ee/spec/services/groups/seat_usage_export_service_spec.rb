# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SeatUsageExportService do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:user) { create(:user) }

  subject(:service) { described_class.new(group, user)}

  describe '#execute', :aggregate_failures do
    before do
      group.add_owner(user)
      group.add_owner(create(:user))
      group.add_developer(create(:user))
      group.add_reporter(create(:user))
      group.add_guest(create(:user))
      # let_it_be(:maria) { create(:group_member, group: group, user: create(:user, name: 'Maria Gomez')) }
      # let_it_be(:john_smith) { create(:group_member, group: group, user: create(:user, name: 'John Smith')) }
      # let_it_be(:john_doe) { create(:group_member, group: group, user: create(:user, name: 'John Doe')) }
      # let_it_be(:sophie) { create(:group_member, group: group, user: create(:user, name: 'Sophie Dupont')) }
    end

    it 'play' do
      byebug
    end
  end
end
