# frozen_string_literal: true

module Quality
  module Seeders
    class DeepDiscussion
      attr_reader :issue

      def initialize(issue:)
        @issue = issue
      end

      def seed
        # could add confidentiality later
        default_params = { noteable_type: 'Issue', noteable_id: issue.id }

        notes_to_save = []

        last_note = nil

        3.times do |n|
          print "."
          author = team.sample
          params = default_params.merge(note: generate_content(author, user_mention: true))
          if last_note
            params = params.merge(in_reply_to_discussion_id: last_note.discussion_id)
          end
          result = ::Notes::BuildService.new(project, author, params).execute
          result.save!
          update_discussions!(result)
          saved_notes << result
          last_note = result
        end

        saved_notes
      end

      private

      attr_accessor :team, :project_issues, :project, :last_note

      def project
        @project ||= issue.project
      end

      def team
        @team ||= project.team.users
      end

      def mention_user(author)
        # somebody other than the author
        [team - [author]].flatten.sample
      end

      def mention_issue
        # some other issue
        [project_issues - [issue]].flatten.sample
      end

      def project_issues
        @project_issues ||= project.issues
      end

      def generate_content(author, user_mention: false, issue_mention: false)
        references = []
        references << mention_user(author).to_reference if user_mention
        references << mention_issue.to_reference if issue_mention
        references.compact! # in case of nils

        return FFaker::Lorem.sentence(2) unless references

        content = references.unshift(FFaker::Lorem.sentence)
        spacer_words = FFaker::Lorem.words(2).join(" ")
        content.join(" #{spacer_words} ")
      end

      def update_discussions!(note)
        # don't want to repeat the logic so we'll reuse this method instead
        ::Notes::CreateService.new(project, note.author).send(:update_discussions, note)
      end
    end
  end
end
