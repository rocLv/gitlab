# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::JobArtifacts do
  include HttpIOHelpers

  shared_examples 'a job with artifacts and trace' do |result_is_array: true|
    context 'with artifacts and trace' do
      let!(:second_job) { create(:ci_build, :trace_artifact, :artifacts, :test_reports, pipeline: pipeline) }

      it 'returns artifacts and trace data', :skip_before_request do
        get api(api_endpoint, api_user)
        json_job = result_is_array ? json_response.find { |job| job['id'] == second_job.id } : json_response

        expect(json_job['artifacts_file']).not_to be_nil
        expect(json_job['artifacts_file']).not_to be_empty
        expect(json_job['artifacts_file']['filename']).to eq(second_job.artifacts_file.filename)
        expect(json_job['artifacts_file']['size']).to eq(second_job.artifacts_file.size)
        expect(json_job['artifacts']).not_to be_nil
        expect(json_job['artifacts']).to be_an Array
        expect(json_job['artifacts'].size).to eq(second_job.job_artifacts.length)
        json_job['artifacts'].each do |artifact|
          expect(artifact).not_to be_nil
          file_type = Ci::JobArtifact.file_types[artifact['file_type']]
          expect(artifact['size']).to eq(second_job.job_artifacts.find_by(file_type: file_type).size)
          expect(artifact['filename']).to eq(second_job.job_artifacts.find_by(file_type: file_type).filename)
          expect(artifact['file_format']).to eq(second_job.job_artifacts.find_by(file_type: file_type).file_format)
        end
      end
    end
  end

  let_it_be(:project, reload: true) do
    create(:project, :repository, public_builds: false)
  end

  let_it_be(:pipeline, reload: true) do
    create(:ci_pipeline, project: project,
                         sha: project.commit.id,
                         ref: project.default_branch)
  end

  let!(:job) do
    create(:ci_build, :success, pipeline: pipeline,
                                artifacts_expire_at: 1.day.since)
  end

  let(:user) { create(:user) }
  let(:api_user) { user }
  let(:reporter) { create(:project_member, :reporter, project: project).user }
  let(:guest) { create(:project_member, :guest, project: project).user }

  before do
    project.add_developer(user)
  end

  describe 'DELETE /projects/:id/jobs/:job_id/artifacts' do
    let!(:job) { create(:ci_build, :artifacts, pipeline: pipeline, user: api_user) }

    before do
      delete api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)
    end

    context 'when user is anonymous' do
      let(:api_user) { nil }

      it 'does not delete artifacts' do
        expect(job.job_artifacts.size).to eq 2
      end

      it 'returns status 401 (unauthorized)' do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with developer' do
      it 'does not delete artifacts' do
        expect(job.job_artifacts.size).to eq 2
      end

      it 'returns status 403 (forbidden)' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with authorized user' do
      let(:maintainer) { create(:project_member, :maintainer, project: project).user }
      let!(:api_user) { maintainer }

      it 'deletes artifacts' do
        expect(job.job_artifacts.size).to eq 0
      end

      it 'returns status 204 (no content)' do
        expect(response).to have_gitlab_http_status(:no_content)
      end
    end
  end

  describe 'GET /projects/:id/jobs/:job_id/artifacts/:artifact_path' do
    context 'when job has artifacts' do
      let(:job) { create(:ci_build, :artifacts, pipeline: pipeline) }

      let(:artifact) do
        'other_artifacts_0.1.2/another-subdirectory/banana_sample.gif'
      end

      context 'when user is anonymous' do
        let(:api_user) { nil }

        context 'when project is public' do
          it 'allows to access artifacts' do
            project.update_column(:visibility_level,
                                  Gitlab::VisibilityLevel::PUBLIC)
            project.update_column(:public_builds, true)

            get_artifact_file(artifact)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'when project is public with builds access disabled' do
          it 'rejects access to artifacts' do
            project.update_column(:visibility_level,
                                  Gitlab::VisibilityLevel::PUBLIC)
            project.update_column(:public_builds, false)

            get_artifact_file(artifact)

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when project is private' do
          it 'rejects access and hides existence of artifacts' do
            project.update_column(:visibility_level,
                                  Gitlab::VisibilityLevel::PRIVATE)
            project.update_column(:public_builds, true)

            get_artifact_file(artifact)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when user is authorized' do
        it 'returns a specific artifact file for a valid path' do
          expect(Gitlab::Workhorse)
            .to receive(:send_artifacts_entry)
            .and_call_original

          get_artifact_file(artifact)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers.to_h)
            .to include('Content-Type' => 'application/json',
                        'Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
        end
      end
    end

    context 'when job does not have artifacts' do
      it 'does not return job artifact file' do
        get_artifact_file('some/artifact')

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def get_artifact_file(artifact_path)
      get api("/projects/#{project.id}/jobs/#{job.id}/" \
              "artifacts/#{artifact_path}", api_user)
    end
  end

  describe 'GET /projects/:id/jobs/:job_id/artifacts' do
    shared_examples 'downloads artifact' do
      let(:download_headers) do
        { 'Content-Transfer-Encoding' => 'binary',
          'Content-Disposition' => %q(attachment; filename="ci_build_artifacts.zip"; filename*=UTF-8''ci_build_artifacts.zip) }
      end

      it 'returns specific job artifacts' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers.to_h).to include(download_headers)
        expect(response.body).to match_file(job.artifacts_file.file.file)
      end
    end

    context 'normal authentication' do
      context 'job with artifacts' do
        context 'when artifacts are stored locally' do
          let(:job) { create(:ci_build, :artifacts, pipeline: pipeline) }

          before do
            get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)
          end

          context 'authorized user' do
            it_behaves_like 'downloads artifact'
          end

          context 'unauthorized user' do
            let(:api_user) { nil }

            it 'does not return specific job artifacts' do
              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end

        context 'when artifacts are stored remotely' do
          let(:proxy_download) { false }

          before do
            stub_artifacts_object_storage(proxy_download: proxy_download)
          end

          let(:job) { create(:ci_build, pipeline: pipeline) }
          let!(:artifact) { create(:ci_job_artifact, :archive, :remote_store, job: job) }

          before do
            job.reload

            get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)
          end

          context 'when proxy download is enabled' do
            let(:proxy_download) { true }

            it 'responds with the workhorse send-url' do
              expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("send-url:")
            end
          end

          context 'when proxy download is disabled' do
            it 'returns location redirect' do
              expect(response).to have_gitlab_http_status(:found)
            end
          end

          context 'authorized user' do
            it 'returns the file remote URL' do
              expect(response).to redirect_to(artifact.file.url)
            end
          end

          context 'unauthorized user' do
            let(:api_user) { nil }

            it 'does not return specific job artifacts' do
              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end

        it 'does not return job artifacts if not uploaded' do
          get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET /projects/:id/artifacts/:ref_name/download?job=name' do
    let(:api_user) { reporter }
    let(:job) { create(:ci_build, :artifacts, pipeline: pipeline, user: api_user) }

    before do
      stub_artifacts_object_storage
      job.success
    end

    def get_for_ref(ref = pipeline.ref, job_name = job.name)
      get api("/projects/#{project.id}/jobs/artifacts/#{ref}/download", api_user), params: { job: job_name }
    end

    context 'when not logged in' do
      let(:api_user) { nil }

      before do
        get_for_ref
      end

      it 'does not find a resource in a private project' do
        expect(project).to be_private
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when logging as guest' do
      let(:api_user) { guest }

      before do
        get_for_ref
      end

      it 'gives 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'non-existing job' do
      shared_examples 'not found' do
        it { expect(response).to have_gitlab_http_status(:not_found) }
      end

      context 'has no such ref' do
        before do
          get_for_ref('TAIL')
        end

        it_behaves_like 'not found'
      end

      context 'has no such job' do
        before do
          get_for_ref(pipeline.ref, 'NOBUILD')
        end

        it_behaves_like 'not found'
      end
    end

    context 'find proper job' do
      shared_examples 'a valid file' do
        context 'when artifacts are stored locally', :sidekiq_might_not_need_inline do
          let(:download_headers) do
            { 'Content-Transfer-Encoding' => 'binary',
              'Content-Disposition' =>
              %Q(attachment; filename="#{job.artifacts_file.filename}"; filename*=UTF-8''#{job.artifacts_file.filename}) }
          end

          it { expect(response).to have_gitlab_http_status(:ok) }
          it { expect(response.headers.to_h).to include(download_headers) }
        end

        context 'when artifacts are stored remotely' do
          let(:job) { create(:ci_build, pipeline: pipeline, user: api_user) }
          let!(:artifact) { create(:ci_job_artifact, :archive, :remote_store, job: job) }

          before do
            job.reload

            get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)
          end

          it 'returns location redirect' do
            expect(response).to have_gitlab_http_status(:found)
          end
        end
      end

      context 'with regular branch' do
        before do
          pipeline.reload
          pipeline.update!(ref: 'master',
                           sha: project.commit('master').sha)

          get_for_ref('master')
        end

        it_behaves_like 'a valid file'
      end

      context 'with branch name containing slash' do
        before do
          pipeline.reload
          pipeline.update!(ref: 'improve/awesome',
                           sha: project.commit('improve/awesome').sha)
        end

        before do
          get_for_ref('improve/awesome')
        end

        it_behaves_like 'a valid file'
      end
    end
  end

  describe 'GET id/jobs/artifacts/:ref_name/raw/*artifact_path?job=name' do
    context 'when job has artifacts' do
      let(:job) { create(:ci_build, :artifacts, pipeline: pipeline, user: api_user) }
      let(:artifact) { 'other_artifacts_0.1.2/another-subdirectory/banana_sample.gif' }
      let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
      let(:public_builds) { true }

      before do
        stub_artifacts_object_storage
        job.success

        project.update!(visibility_level: visibility_level,
                        public_builds: public_builds)

        get_artifact_file(artifact)
      end

      context 'when user is anonymous' do
        let(:api_user) { nil }

        context 'when project is public' do
          let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
          let(:public_builds) { true }

          it 'allows to access artifacts', :sidekiq_might_not_need_inline do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response.headers.to_h)
              .to include('Content-Type' => 'application/json',
                          'Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
          end
        end

        context 'when project is public with builds access disabled' do
          let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
          let(:public_builds) { false }

          it 'rejects access to artifacts' do
            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response).to have_key('message')
            expect(response.headers.to_h)
              .not_to include('Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
          end
        end

        context 'when project is private' do
          let(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }
          let(:public_builds) { true }

          it 'rejects access and hides existence of artifacts' do
            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response).to have_key('message')
            expect(response.headers.to_h)
              .not_to include('Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
          end
        end
      end

      context 'when user is authorized' do
        let(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }
        let(:public_builds) { true }

        it 'returns a specific artifact file for a valid path', :sidekiq_might_not_need_inline do
          expect(Gitlab::Workhorse)
            .to receive(:send_artifacts_entry)
                  .and_call_original

          get_artifact_file(artifact)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers.to_h)
            .to include('Content-Type' => 'application/json',
                        'Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
        end
      end

      context 'with branch name containing slash' do
        before do
          pipeline.reload
          pipeline.update!(ref: 'improve/awesome',
                           sha: project.commit('improve/awesome').sha)
        end

        it 'returns a specific artifact file for a valid path', :sidekiq_might_not_need_inline do
          get_artifact_file(artifact, 'improve/awesome')

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers.to_h)
            .to include('Content-Type' => 'application/json',
                        'Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
        end
      end

      context 'non-existing job' do
        shared_examples 'not found' do
          it { expect(response).to have_gitlab_http_status(:not_found) }
        end

        context 'has no such ref' do
          before do
            get_artifact_file('some/artifact', 'wrong-ref')
          end

          it_behaves_like 'not found'
        end

        context 'has no such job' do
          before do
            get_artifact_file('some/artifact', pipeline.ref, 'wrong-job-name')
          end

          it_behaves_like 'not found'
        end
      end
    end

    context 'when job does not have artifacts' do
      let(:job) { create(:ci_build, pipeline: pipeline, user: api_user) }

      it 'does not return job artifact file' do
        get_artifact_file('some/artifact')

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def get_artifact_file(artifact_path, ref = pipeline.ref, job_name = job.name)
      get api("/projects/#{project.id}/jobs/artifacts/#{ref}/raw/#{artifact_path}", api_user), params: { job: job_name }
    end
  end

  describe 'POST /projects/:id/jobs/:job_id/artifacts/keep' do
    before do
      post api("/projects/#{project.id}/jobs/#{job.id}/artifacts/keep", user)
    end

    context 'artifacts did not expire' do
      let(:job) do
        create(:ci_build, :trace_artifact, :artifacts, :success,
               project: project, pipeline: pipeline, artifacts_expire_at: Time.now + 7.days)
      end

      it 'keeps artifacts' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(job.reload.artifacts_expire_at).to be_nil
      end
    end

    context 'no artifacts' do
      let(:job) { create(:ci_build, project: project, pipeline: pipeline) }

      it 'responds with not found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /projects/:id/artifacts' do
    let!(:job) { create(:ci_build, :artifacts, pipeline: pipeline, user: api_user) }

    subject do
      delete api("/projects/#{project.id}/artifacts", api_user)
    end

    context 'when user is anonymous' do
      let(:api_user) { nil }

      it 'returns status 401 (unauthorized)' do
        subject
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with developer' do
      it 'returns status 403 (forbidden)' do
        subject
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with authorized user' do
      let(:maintainer) { create(:project_member, :maintainer, project: project).user }
      let!(:api_user) { maintainer }

      it 'enqueues worker' do
        expect { subject }.to change(::Ci::DeleteProjectJobArtifactsWorker.jobs, :size).by(1)

        job = ::Ci::DeleteProjectJobArtifactsWorker.jobs.last
        expect(job['args'][0]).to eq(project.id)
      end

      it 'returns status 204 (no content)' do
        subject
        expect(response).to have_gitlab_http_status(:no_content)
      end
    end
  end
end
