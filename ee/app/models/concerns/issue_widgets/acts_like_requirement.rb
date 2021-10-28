# frozen_string_literal: true

module IssueWidgets
  module ActsLikeRequirement
    extend ActiveSupport::Concern

    included do
      attr_accessor :requirement_sync_error

      after_validation :invalidate_if_sync_error, on: [:update, :create]

      # This will mean that non-Requirement issues essentially ignore this relationship and always return []
      has_many :test_reports, -> { joins(:requirement_issue).where(issues: { issue_type: WorkItem::Type.base_types[:requirement] }) },
               foreign_key: :issue_id, inverse_of: :requirement_issue, class_name: 'RequirementsManagement::TestReport'
      has_one :requirement, class_name: 'RequirementsManagement::Requirement'

      scope :for_requirement_iid, -> (iid) { joins(:requirement).where(requirements: { iid: iid })}
      scope :include_last_test_report_with_state, -> do
        joins(:test_reports).where.not( test_reports: { state: nil } ).order(issue_id: :desc).limit(1)
      end
      scope :with_last_test_report_state, -> (state) do
        include_last_test_report_with_state.where( test_reports: { state: state } )
      end
      scope :without_test_reports, -> do
        left_joins(:test_reports).where(requirements_management_test_reports: { issue_id: nil })
      end
    end

    def requirement_sync_error!
      self.requirement_sync_error = true
    end

    def invalidate_if_sync_error
      return unless requirement? # No need to invalidate if issue_type != requirement
      return unless requirement_sync_error
      return unless requirement

      # Mirror errors from requirement so that users can adjust accordingly
      errors = requirement.errors.full_messages.to_sentence
      errors = errors.presence || "Associated requirement was invalid and changes could not be applied."
      self.errors.add(:base, errors)
    end

    def latest_report
      test_reports.order(created_at: :desc).first
    end

    def last_test_report_state
      latest_report&.state
    end

    def last_test_report_manually_created?
      latest_report&.build.nil?
    end
  end
end
