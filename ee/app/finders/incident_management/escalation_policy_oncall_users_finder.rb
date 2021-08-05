# frozen_string_literal: true

module IncidentManagement
  # Returns users who are oncall for the escalation policy, for each rule in the policy.
  # If an EscalationRule uses a schedule, then all users currently on-call
  # will be returned, otherwise the user directly associated to the rule will be returned.

  # Returns an array of schedule, user tuples.
  class EscalationPolicyOncallUsersFinder
    include Gitlab::Utils::StrongMemoize

    def initialize(escalation_policy)
      @escalation_policy = escalation_policy
      @project = escalation_policy.project
      @users_on_call = []
    end

    def execute
      escalation_policy.rules.not_removed.each do |rule|
        if rule.oncall_schedule
          add_schedule_oncall_users(rule.oncall_schedule)
        else
          users_on_call << { schedule: nil, user: rule.user }
        end
      end

      users_on_call
    end

    private

    attr_reader :project, :escalation_policy, :users_on_call

    def add_schedule_oncall_users(schedule)
      users = OncallUsersFinder.new(project, schedule: schedule).execute # rubocop: disable CodeReuse/Finder

      users.each do |user|
        users_on_call << { schedule: schedule, user: user }
      end
    end
  end
end
