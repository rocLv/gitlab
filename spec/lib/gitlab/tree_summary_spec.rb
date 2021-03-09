# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TreeSummary do
  include RepoHelpers
  using RSpec::Parameterized::TableSyntax

  let(:project) { create(:project, :empty_repo) }
  let(:repo) { project.repository }
  let(:commit) { repo.head_commit }
  let_it_be(:user) { create(:user) }

  let(:path) { nil }
  let(:offset) { nil }
  let(:limit) { nil }

  subject(:summary) { described_class.new(commit, project, user, path: path, offset: offset, limit: limit) }

  describe '#initialize' do
    it 'defaults offset to 0' do
      expect(summary.offset).to eq(0)
    end

    it 'defaults limit to 25' do
      expect(summary.limit).to eq(25)
    end
  end

  describe '#summarize' do
    let(:project) { create(:project, :custom_repo, files: { 'a.txt' => '' }) }

    subject(:summarized) { summary.summarize }

    it 'returns an array of entries, and an array of commits' do
      expect(summarized).to be_a(Array)
      expect(summarized.size).to eq(2)

      entries, commits = *summarized
      aggregate_failures do
        expect(entries).to contain_exactly(
          a_hash_including(file_name: 'a.txt', commit: have_attributes(id: commit.id))
        )

        expect(commits).to match_array(entries.map { |entry| entry[:commit] })
      end
    end

    context 'when offset is over the limit' do
      let(:offset) { 100 }

      it 'returns an empty array' do
        expect(summarized).to eq([[], []])
      end
    end

    context 'with caching', :use_clean_rails_memory_store_caching do
      subject { Rails.cache.fetch(key) }

      context 'Repository tree cache' do
        let(:key) { ['projects', project.id, 'content', commit.id, path] }

        it 'creates a cache for repository content' do
          summarized

          is_expected.to eq([{ file_name: 'a.txt', type: :blob }])
        end
      end

      context 'Commits list cache' do
        let(:offset) { 0 }
        let(:limit) { 25 }
        let(:key) { ['projects', project.id, 'last_commits', commit.id, path, offset, limit] }

        it 'creates a cache for commits list' do
          summarized

          is_expected.to eq('a.txt' => commit.to_hash)
        end

        context 'when commit has a very long message' do
          before do
            repo.create_file(
              project.creator,
              'long.txt',
              '',
              message: message,
              branch_name: project.default_branch_or_master
            )
          end

          let(:message) { 'a' * 1025 }
          let(:expected_message) { message[0...1021] + '...' }

          it 'truncates commit message to 1 kilobyte' do
            summarized

            is_expected.to include('long.txt' => a_hash_including(message: expected_message))
          end
        end
      end
    end
  end

  describe '#summarize (entries)' do
    let(:limit) { 4 }

    custom_files = {
      'a.txt' => '',
      'b.txt' => '',
      'directory/c.txt' => '',
      ':dir/test.txt' => '',
      ':file' => ''
    }

    let!(:project) { create(:project, :custom_repo, files: custom_files) }
    let(:commit) { repo.head_commit }

    subject(:entries) { summary.summarize.first }

    it 'summarizes the entries within the window' do
      is_expected.to contain_exactly(
        a_hash_including(type: :tree, file_name: 'directory'),
        a_hash_including(type: :blob, file_name: 'a.txt'),
        a_hash_including(type: :blob, file_name: ':file'),
        a_hash_including(type: :tree, file_name: ':dir')
        # b.txt is excluded by the limit
      )
    end

    it 'references the commit and commit path in entries' do
      # There are 2 trees and the summary is not ordered
      entry = entries.find { |entry| entry[:commit].id == commit.id }
      expected_commit_path = Gitlab::Routing.url_helpers.project_commit_path(project, commit)

      expect(entry[:commit]).to be_a(::Commit)
      expect(entry[:commit_path]).to eq(expected_commit_path)
      expect(entry[:commit_title_html]).to eq(commit.message)
    end

    context 'in a good subdirectory' do
      let(:path) { 'directory' }

      it 'summarizes the entries in the subdirectory' do
        is_expected.to contain_exactly(a_hash_including(type: :blob, file_name: 'c.txt'))
      end
    end

    context 'in a subdirectory with a pathspec character' do
      let(:path) { ':dir' }

      it 'summarizes the entries in the subdirectory' do
        is_expected.to contain_exactly(a_hash_including(type: :blob, file_name: 'test.txt'))
      end
    end

    context 'in a non-existent subdirectory' do
      let(:path) { 'tmp' }

      it { is_expected.to be_empty }
    end

    context 'custom offset and limit' do
      let(:offset) { 4 }

      it 'returns entries from the offset' do
        is_expected.to contain_exactly(a_hash_including(type: :blob, file_name: 'b.txt'))
      end
    end
  end

  describe '#summarize (commits)' do
    # This is a commit in the master branch of the gitlab-test repository that
    # satisfies certain assumptions these tests depend on
    let(:test_commit_sha) { '7975be0116940bf2ad4321f79d02a55c5f7779aa' }
    let(:whitespace_commit_sha) { '66eceea0db202bb39c4e445e8ca28689645366c5' }

    let(:project) { create(:project, :repository) }
    let(:commit) { repo.commit(test_commit_sha) }
    let(:limit) { nil }
    let(:entries) { summary.summarize.first }

    subject(:commits) do
      summary.summarize.last
    end

    it 'returns an Array of ::Commit objects' do
      is_expected.not_to be_empty
      is_expected.to all(be_kind_of(::Commit))
    end

    it 'deduplicates commits when multiple entries reference the same commit' do
      expect(commits.size).to be < entries.size
    end

    context 'in a subdirectory' do
      let(:path) { 'files' }

      it 'returns commits for entries in the subdirectory' do
        expect(commits).to satisfy_one { |c| c.id == whitespace_commit_sha }
      end
    end

    context 'in a subdirectory with non-ASCII filenames' do
      let(:path) { 'encoding' }

      it 'returns commits for entries in the subdirectory' do
        entry = entries.find { |x| x[:file_name] == 'テスト.txt' }

        expect(entry).to be_a(Hash)
        expect(entry).to include(:commit)
      end
    end

    context 'rendering commits' do
      it 'does not perform N + 1 request' do
        summary

        queries = ActiveRecord::QueryRecorder.new { summary.summarize }

        expect(queries.count).to be <= 3
      end
    end
  end

  describe 'References in commit messages' do
    let_it_be(:project) { create(:project, :empty_repo) }
    let_it_be(:issue) { create(:issue, project: project) }
    let(:entries) { summary.summarize.first }
    let(:entry) { entries.find { |entry| entry[:file_name] == 'issue.txt' } }

    before_all do
      create_file_in_repo(project, 'master', 'master', 'issue.txt', '', commit_message: "Issue ##{issue.iid}")
    end

    where(:project_visibility, :user_role, :issue_confidential, :expected_result) do
      'private'  | :guest    | false | true
      'private'  | :guest    | true  | false
      'private'  | :reporter | false | true
      'private'  | :reporter | true  | true

      'internal' | :guest    | false | true
      'internal' | :guest    | true  | false
      'internal' | :reporter | false | true
      'internal' | :reporter | true  | true

      'public'   | :guest    | false | true
      'public'   | :guest    | true  | false
      'public'   | :reporter | false | true
      'public'   | :reporter | true  | true
    end

    with_them do
      subject { entry[:commit_title_html].include?("title=\"#{issue.title}\"") }

      before do
        project.add_role(user, user_role)
        project.update!(visibility_level: Gitlab::VisibilityLevel.level_value(project_visibility))
        issue.update!(confidential: issue_confidential)
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#more?' do
    let(:path) { 'tmp/more' }

    where(:num_entries, :offset, :limit, :expected_result) do
      0 | 0 | 0 | false
      0 | 0 | 1 | false

      1 | 0 | 0 | true
      1 | 0 | 1 | false
      1 | 1 | 0 | false
      1 | 1 | 1 | false

      2 | 0 | 0 | true
      2 | 0 | 1 | true
      2 | 0 | 2 | false
      2 | 0 | 3 | false
      2 | 1 | 0 | true
      2 | 1 | 1 | false
      2 | 2 | 0 | false
      2 | 2 | 1 | false
    end

    with_them do
      before do
        create_file('dummy', path: 'other') if num_entries == 0
        1.upto(num_entries) { |n| create_file(n, path: path) }
      end

      subject { summary.more? }

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#next_offset' do
    let(:path) { 'tmp/next_offset' }

    where(:num_entries, :offset, :limit, :expected_result) do
      0 | 0 | 0 | 0
      0 | 0 | 1 | 1
      0 | 1 | 0 | 1
      0 | 1 | 1 | 1

      1 | 0 | 0 | 0
      1 | 0 | 1 | 1
      1 | 1 | 0 | 1
      1 | 1 | 1 | 2
    end

    with_them do
      before do
        create_file('dummy', path: 'other') if num_entries == 0
        1.upto(num_entries) { |n| create_file(n, path: path) }
      end

      subject { summary.next_offset }

      it { is_expected.to eq(expected_result) }
    end
  end

  def create_file(unique, path:)
    repo.create_file(
      project.creator,
      "#{path}/file-#{unique}.txt",
      'content',
      message: "Commit message #{unique}",
      branch_name: 'master'
    )
  end
end
