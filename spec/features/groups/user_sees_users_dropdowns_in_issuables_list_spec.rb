# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > User sees users dropdowns in issuables list', :js do
  include FilteredSearchHelpers

  let(:entity) { create(:group) }
  let(:user_in_dropdown) { create(:user) }
  let!(:user_not_in_dropdown) { create(:user) }
  let!(:project) { create(:project, group: entity) }

  before do
    entity.add_developer(user_in_dropdown)
    sign_in(user_in_dropdown)
  end

  describe 'issue list user dropdown behaviors' do
    let!(:issuable) { create(:issue, project: project) }
    let(:issuables_path) { issues_group_path(entity) }

    describe "author dropdown" do
      it 'only includes members of the project/group' do
        visit issuables_path

        select_tokens 'Author', '=', submit: false

        expect_suggestion(user_in_dropdown.name)
        expect_no_suggestion(user_not_in_dropdown.name)
      end
    end

    describe "assignee dropdown" do
      it 'only includes members of the project/group' do
        visit issuables_path

        select_tokens 'Assignee', '=', submit: false

        expect_suggestion(user_in_dropdown.name)
        expect_no_suggestion(user_not_in_dropdown.name)
      end
    end
  end

  describe 'merge request list user dropdown behaviors' do
    let!(:issuable) { create(:merge_request, source_project: project) }
    let(:issuables_path) { merge_requests_group_path(entity) }

    %w[author assignee].each do |dropdown|
      describe "#{dropdown} dropdown" do
        it 'only includes members of the project/group' do
          visit issuables_path

          filtered_search.set("#{dropdown}:=")

          expect(find("#js-dropdown-#{dropdown} .filter-dropdown")).to have_content(user_in_dropdown.name)
          expect(find("#js-dropdown-#{dropdown} .filter-dropdown")).not_to have_content(user_not_in_dropdown.name)
        end
      end
    end
  end
end
