# frozen_string_literal: true

module API
  module Helpers
    module SnippetsHelpers
      extend Grape::API::Helpers

      params :raw_file_params do
        requires :file_path, type: String, file_path: true, desc: 'The url encoded path to the file, e.g. lib%2Fclass%2Erb'
        requires :ref, type: String, desc: 'The name of branch, tag or commit'
      end

      params :create_file_params do
        optional :files, type: Array, desc: 'An array of files' do
          requires :file_path, type: String, file_path: true, allow_blank: false, desc: 'The path of a snippet file'
          requires :content, type: String, allow_blank: false, desc: 'The content of a snippet file'
        end

        optional :content, type: String, allow_blank: false, desc: 'The content of a snippet'

        given :content do
          requires :file_name, type: String, desc: 'The name of a snippet file'
        end

        mutually_exclusive :files, :content

        exactly_one_of :files, :content
      end

      def content_for(snippet)
        if snippet.empty_repo?
          env['api.format'] = :txt
          content_type 'text/plain'
          header['Content-Disposition'] = 'attachment'

          snippet.content
        else
          blob = snippet.blobs.first

          send_git_blob(blob.repository, blob)
        end
      end

      def file_content_for(snippet)
        repo = snippet.repository
        commit = repo.commit(params[:ref])
        not_found!('Reference') unless commit

        blob = repo.blob_at(commit.sha, params[:file_path])
        not_found!('File') unless blob

        send_git_blob(repo, blob)
      end
    end

    def process_file_args(args)
      args[:snippet_actions] = args.delete(:files)&.map do |file|
        file[:action] = :create
        file.symbolize_keys
      end
    end
  end
end
