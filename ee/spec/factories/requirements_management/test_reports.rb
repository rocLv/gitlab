# frozen_string_literal: true

FactoryBot.define do
  factory :test_report, class: 'RequirementsManagement::TestReport' do
    author
    requirement
    build factory: :ci_build
    state { :passed }

    trait :for_requirement_issue do
      requirement { nil }
      requirement_issue
    end
  end
end
