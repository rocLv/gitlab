# frozen_string_literal: true

require 'spec_helper'

describe SnippetsFinder do
  include ExternalAuthorizationServiceHelpers
  include Gitlab::Allowable

  describe '#initialize' do
    it 'raises ArgumentError when a project and author are given' do
      user = build(:user)
      project = build(:project)

      expect { described_class.new(user, author: user, project: project) }
        .to raise_error(ArgumentError)
    end
  end

  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:other_user) { create(:user) }
    let_it_be(:admin) { create(:admin) }
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, group: group) }

    let_it_be(:private_personal_snippet) { create(:personal_snippet, :private, author: user) }
    let_it_be(:internal_personal_snippet) { create(:personal_snippet, :internal, author: user) }
    let_it_be(:public_personal_snippet) { create(:personal_snippet, :public, author: user) }
    let_it_be(:secret_personal_snippet) { create(:personal_snippet, :secret, author: user) }

    let_it_be(:private_project_snippet) { create(:project_snippet, :private, project: project) }
    let_it_be(:internal_project_snippet) { create(:project_snippet, :internal, project: project) }
    let_it_be(:public_project_snippet) { create(:project_snippet, :public, project: project) }

    context 'filter by scope' do
      it "returns all snippets for 'all' scope" do
        expect(find_snippets(:all)).to contain_exactly(
          private_personal_snippet, internal_personal_snippet, public_personal_snippet,
          internal_project_snippet, public_project_snippet, secret_personal_snippet
        )
      end

      it "returns all snippets for 'are_private' scope" do
        expect(find_snippets(:are_private)).to contain_exactly(private_personal_snippet)
      end

      it "returns all snippets for 'are_internal' scope" do
        expect(find_snippets(:are_internal)).to contain_exactly(internal_personal_snippet, internal_project_snippet)
      end

      it "returns all snippets for 'are_public' scope" do
        expect(find_snippets(:are_public)).to contain_exactly(public_personal_snippet, public_project_snippet)
      end

      it "returns all snippets for 'are_secret' scope" do
        expect(find_snippets(:are_secret)).to contain_exactly(secret_personal_snippet)
      end

      context 'when the user it not the author' do
        let(:user) { other_user }

        it "returns all snippets for 'all' scope" do
          expect(find_snippets(:all)).to contain_exactly(
            internal_personal_snippet, public_personal_snippet,
            internal_project_snippet, public_project_snippet
          )
        end
      end

      def find_snippets(scope)
        described_class.new(user, scope: scope).execute
      end
    end

    context 'filter by author' do
      it 'returns all public and internal snippets' do
        expect(find_snippets(other_user)).to contain_exactly(internal_personal_snippet, public_personal_snippet)
      end

      it 'returns internal snippets' do
        expect(find_snippets(user, scope: :are_internal)).to contain_exactly(internal_personal_snippet)
      end

      it 'returns private snippets' do
        expect(find_snippets(user, scope: :are_private)).to contain_exactly(private_personal_snippet)
      end

      it 'returns public snippets' do
        expect(find_snippets(user, scope: :are_public)).to contain_exactly(public_personal_snippet)
      end

      it 'returns secret snippets' do
        expect(find_snippets(user, scope: :are_secret)).to contain_exactly(secret_personal_snippet)
      end

      it 'returns all snippets' do
        expect(find_snippets(user)).to contain_exactly(private_personal_snippet, internal_personal_snippet, public_personal_snippet, secret_personal_snippet)
      end

      it 'returns only public snippets if unauthenticated user' do
        expect(find_snippets(nil)).to contain_exactly(public_personal_snippet)
      end

      it 'returns all snippets for an admin' do
        expect(find_snippets(admin)).to contain_exactly(private_personal_snippet, internal_personal_snippet, public_personal_snippet)
      end

      def find_snippets(search_user, scope: nil)
        described_class.new(search_user, author: user, scope: scope).execute
      end
    end

    context 'project snippets' do
      it 'returns public personal and project snippets for unauthorized user' do
        expect(find_snippets(nil)).to contain_exactly(public_project_snippet)
      end

      it 'returns public and internal snippets for non project members' do
        expect(find_snippets(user)).to contain_exactly(internal_project_snippet, public_project_snippet)
      end

      it 'returns public snippets for non project members' do
        expect(find_snippets(user, scope: :are_public)).to contain_exactly(public_project_snippet)
      end

      it 'returns internal snippets for non project members' do
        snippets = described_class.new(user, project: project, scope: :are_internal).execute

        expect(snippets).to contain_exactly(internal_project_snippet)
      end

      it 'does not return private snippets for non project members' do
        expect(find_snippets(user, scope: :are_private)).to be_empty
      end

      it 'returns all snippets for project members' do
        project.add_developer(user)

        expect(find_snippets(user)).to contain_exactly(private_project_snippet, internal_project_snippet, public_project_snippet)
      end

      it 'returns private snippets for project members' do
        project.add_developer(user)

        expect(find_snippets(user, scope: :are_private)).to contain_exactly(private_project_snippet)
      end

      it 'returns all snippets for an admin' do
        expect(find_snippets(admin)).to contain_exactly(private_project_snippet, internal_project_snippet, public_project_snippet)
      end

      context 'filter by author' do
        let!(:other_user) { create(:user) }
        let!(:other_private_project_snippet) { create(:project_snippet, :private, project: project, author: other_user) }
        let!(:other_internal_project_snippet) { create(:project_snippet, :internal, project: project, author: other_user) }
        let!(:other_public_project_snippet) { create(:project_snippet, :public, project: project, author: other_user) }

        it 'returns all snippets for project members' do
          project.add_developer(user)

          snippets = described_class.new(user, author: other_user).execute

          expect(snippets)
            .to contain_exactly(
              other_private_project_snippet,
              other_internal_project_snippet,
              other_public_project_snippet
            )
        end
      end

      def find_snippets(search_user, author: nil, scope: nil)
        described_class.new(search_user, author: author, scope: scope, project: project).execute
      end
    end

    context 'explore snippets' do
      it 'returns only public personal snippets for unauthenticated users' do
        expect(find_snippets(nil)).to contain_exactly(public_personal_snippet)
      end

      it 'also returns internal personal snippets for authenticated users' do
        expect(find_snippets(user)).to contain_exactly(
          internal_personal_snippet, public_personal_snippet
        )
      end

      it 'returns all personal snippets for admins' do
        expect(find_snippets(admin)).to contain_exactly(
          private_personal_snippet, internal_personal_snippet, public_personal_snippet
        )
      end

      def find_snippets(search_user)
        described_class.new(search_user, explore: true).execute
      end
    end

    context 'when the user cannot read cross project' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }
      end

      it 'returns only personal snippets when the user cannot read cross project' do
        expect(described_class.new(user).execute).to contain_exactly(
          private_personal_snippet, internal_personal_snippet, public_personal_snippet, secret_personal_snippet
        )
      end
    end
  end

  it_behaves_like 'snippet visibility'

  context 'external authorization' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let!(:snippet) { create(:project_snippet, :public, project: project) }

    subject { described_class.new(user, project: project).execute }

    before do
      project.add_maintainer(user)
    end

    it_behaves_like 'a finder with external authorization service' do
      let!(:subject) { create(:project_snippet, project: project) }
      let(:project_params) { { project: project } }
    end

    it 'includes the result if the external service allows access' do
      external_service_allow_access(user, project)

      expect(subject).to contain_exactly(snippet)
    end

    it 'does not include any results if the external service denies access' do
      external_service_deny_access(user, project)

      expect(subject).to be_empty
    end
  end
end
