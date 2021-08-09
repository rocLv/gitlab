# frozen_string_literal: true

module IncidentManagement
  # Returns users who are oncall by reading shifts from the DB.
  # The DB is the historical record, so we should adhere to it
  # when it is available. If rotations are missing persited
  # shifts for some reason, we'll fallback to a generated shift.
  # It may also be possible that no one is on call for a rotation.
  class OncallUsersFinder
    include Gitlab::Utils::StrongMemoize

    # @param project [Project]
    # @option oncall_at [ActiveSupport::TimeWithZone]
    #                   Limits users to only those
    #                   on-call at the specified time.
    # @option schedule [IncidentManagement::OncallSchedule]
    #                   Limits the users to rotations within a
    #                   specific schedule
    # @option rotations ActiveRecord::Relation<IncidentManagement::OncallRotation>
    #                   Limits the users to the rotations given.
    # @option include_schedule Boolean
    #                   Returns the users with the schedule they are on-call for.
    def initialize(project, oncall_at: Time.current, schedule: nil, rotations: nil, include_schedule: false)
      @project = project
      @oncall_at = oncall_at
      @schedule = schedule
      @include_schedule = include_schedule
      @rotations = rotations || find_rotations
    end

    # @return [User::ActiveRecord_Relation], or [{user: User, Schedule: IncidentManagement::OncallSchedule}]
    def execute
      return User.none unless Gitlab::IncidentManagement.oncall_schedules_available?(project)
      return User.none unless users.present?

      if include_schedule
        users_with_schedules
      else
        users
      end
    end

    private

    attr_reader :project, :oncall_at, :schedule, :include_schedule, :rotations

    def users_with_schedules
      shifts.map do |shift|
        {
          user: users.detect { |u| u.id == shift.last },
          schedule: schedules.detect { |s| s.id == shift.second }
        }
      end
    end

    def users
      strong_memoize(:users) do
        User.id_in(user_ids_for_persisted_shifts.concat(user_ids_for_predicted_shifts))
      end
    end

    def schedules
      strong_memoize(:schedules) do
        IncidentManagement::OncallSchedule.id_in(schedule_ids_for_persisted_shifts.concat(schedule_ids_for_predicted_shifts))
      end
    end

    def shifts
      ids_for_persisted_shifts.concat(ids_for_predicted_shifts)
    end

    # Persisted shifts
    def rotation_ids_for_persisted_shifts
      ids_for_persisted_shifts.flat_map(&:first)
    end

    def schedule_ids_for_persisted_shifts
      ids_for_persisted_shifts.flat_map(&:second)
    end

    def user_ids_for_persisted_shifts
      ids_for_persisted_shifts.flat_map(&:last)
    end

    # Predicted shifts
    def schedule_ids_for_predicted_shifts
      ids_for_predicted_shifts.flat_map(&:second)
    end

    def user_ids_for_predicted_shifts
      ids_for_predicted_shifts.flat_map(&:last)
    end

    def find_rotations
      strong_memoize(:rotations) do
        schedule ? schedule.rotations : project.incident_management_oncall_rotations
      end
    end

    # @return [Array<[rotation_id, schedule_id, user_id]>]
    # @example - [ [1, 24, 16], [2, 36, 200] ]
    def ids_for_persisted_shifts
      strong_memoize(:ids_for_persisted_shifts) do
        rotations
          .merge(IncidentManagement::OncallShift.for_timestamp(oncall_at))
          .pluck_id_schedule_id_user_id
      end
    end

    def ids_for_predicted_shifts
      strong_memoize(:ids_for_predicted_shifts) do
        rotations_without_persisted_shifts.map do |rotation|
          next [] unless shift = IncidentManagement::OncallShiftGenerator.new(rotation).for_timestamp(oncall_at)

          [rotation.id, rotation.oncall_schedule_id, shift.participant.user_id]
        end
      end
    end

    def rotations_without_persisted_shifts
      rotations
        .except_ids(rotation_ids_for_persisted_shifts)
        .with_shift_generation_associations
    end
  end
end
