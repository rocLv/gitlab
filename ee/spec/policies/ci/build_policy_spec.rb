require 'spec_helper'

describe Ci::BuildPolicy do
  using RSpec::Parameterized::TableSyntax

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }

  let(:policy) do
    described_class.new(user, build)
  end

  describe '#update_build?' do
    let(:environment) { create(:environment, project: project, name: 'production') }
    let(:build) { create(:ci_build, pipeline: pipeline, environment: 'production', ref: 'development') }

    subject { user.can?(:update_build, build) }

    context 'when protected environment feature is not available' do
      where(:access_level, :result) do
        :guest      | false
        :reporter   | false
        :developer  | true
        :maintainer | true
        :admin      | true
      end

      with_them do
        before do
          allow(project).to receive(:feature_available?)
          .with(:protected_environments).and_return(false)

          if access_level == :admin
            user.update_attribute(:admin, true)
          elsif access_level.present?
            project.add_user(user, access_level)
          end
        end

        it { is_expected.to eq(result) }
      end
    end

    context 'when protected environments feature is available' do
      before do
        allow(project).to receive(:feature_available?)
          .with(:protected_environments).and_return(true)
      end

      context 'when environment is protected' do
        let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

        context 'when user has access to it' do
          where(:access_level, :result) do
            :guest      | false
            :reporter   | false
            :developer  | true
            :maintainer | true
            :admin      | true
          end

          with_them do
            before do
              protected_environment.deploy_access_levels.create(user: user)

              if access_level == :admin
                user.update_attribute(:admin, true)
              elsif access_level.present?
                project.add_user(user, access_level)
              end
            end

            it { is_expected.to eq(result) }
          end
        end

        context 'when user does not have access to it' do
          where(:access_level, :result) do
            :guest      | false
            :reporter   | false
            :developer  | false
            :maintainer | false
            :admin      | true
          end

          with_them do
            before do
              protected_environment

              if access_level == :admin
                user.update_attribute(:admin, true)
              elsif access_level.present?
                project.add_user(user, access_level)
              end
            end

            it { is_expected.to eq(result) }
          end
        end
      end

      context 'when environment is not protected' do
        where(:access_level, :result) do
          :guest      | false
          :reporter   | false
          :developer  | true
          :maintainer | true
          :admin      | true
        end

        with_them do
          before do
            if access_level == :admin
              user.update_attribute(:admin, true)
            elsif access_level.present?
              project.add_user(user, access_level)
            end
          end

          it { is_expected.to eq(result) }
        end
      end
    end
  end
end
