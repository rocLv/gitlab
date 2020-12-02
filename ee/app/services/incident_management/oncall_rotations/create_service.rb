# frozen_string_literal: true

module IncidentManagement
  module OncallRotations
    class CreateService
      # @param schedule [IncidentManagement::OncallSchedule]
      # @param project [Project]
      # @param user [User]
      # @param params [Hash<Symbol,Any>]
      # @param params - name [String] The name of the on-call rotation.
      # @param params - rotation_length [Integer] The length of the rotation.
      # @param params - rotation_length_unit [String] The unit of the rotation length. (One of 'hours', days', 'weeks')
      # @param params - starts_at [DateTime] The datetime the rotation starts on.
      # @param params - participants [Array<hash>] An array of hashes defining participants of the on-call rotations.
      #                 - participant [User] The user who is part of the rotation
      #                 - color_palette [String] The color palette to assign to the on-call user, for example: "blue".
      #                 - color_weight [String] The color weight to assign to for the on-call user, for example "500". Max 4 chars.
      def initialize(schedule, project, user, params)
        @schedule = schedule
        @project = project
        @current_user = user
        @params = params
      end

      def execute
        return error_no_license unless available?
        return error_no_permissions unless allowed?

        oncall_rotation = schedule.oncall_rotations.create(params.except(:participants))

        return error_in_create(oncall_rotation) unless oncall_rotation.persisted?

        new_participants = params[:participants].map do |participant|
          OncallParticipant.new(
            oncall_rotation: oncall_rotation,
            participant: participant[:user],
            color_palette:  participant[:color_palette],
            color_weight: participant[:color_weight]
          )
        end

        OncallParticipant.bulk_insert!(new_participants)

        success(oncall_rotation)
      end

      private

      attr_reader :schedule, :project, :current_user, :params, :participants

      def allowed?
        Ability.allowed?(current_user, :admin_incident_management_oncall_schedule, project)
      end

      def available?
        Feature.enabled?(:oncall_schedules_mvc, project) &&
          project.feature_available?(:oncall_schedules)
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def success(oncall_rotation)
        ServiceResponse.success(payload: { oncall_rotation: oncall_rotation })
      end

      def error_no_permissions
        error('You have insufficient permissions to create an on-call rotation for this project')
      end

      def error_no_license
        error('Your license does not support on-call rotations')
      end

      def error_in_create(oncall_rotation)
        error(oncall_rotation.errors.full_messages.to_sentence)
      end
    end
  end
end
