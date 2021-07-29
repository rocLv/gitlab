# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceSetting do
  let(:group) { create(:group) }
  let(:setting) { group.namespace_settings }

  describe '#prevent_forking_outside_group?' do
    context 'with feature available' do
      before do
        stub_licensed_features(group_forking_protection: true)
      end

      context 'group with no associated saml provider' do
        before do
          setting.update!(prevent_forking_outside_group: true)
        end

        it 'returns namespace setting' do
          expect(setting.prevent_forking_outside_group?).to eq(true)
        end
      end

      context 'group with associated saml provider' do
        before do
          stub_licensed_features(group_saml: true, group_forking_protection: true)
        end

        context 'when it is configured to true on saml level' do
          before do
            setting.update!(prevent_forking_outside_group: true)
            create(:saml_provider, :enforced_group_managed_accounts, prohibited_outer_forks: true, group: group)
          end

          it 'returns true' do
            expect(setting.prevent_forking_outside_group?).to eq(true)
          end
        end

        context 'when it is configured to false on saml level' do
          before do
            create(:saml_provider, :enforced_group_managed_accounts, prohibited_outer_forks: false, group: group)
          end

          it 'returns false' do
            expect(setting.prevent_forking_outside_group?).to eq(false)
          end

          context 'when setting is configured on namespace level' do
            before do
              setting.update!(prevent_forking_outside_group: true)
            end

            it 'returns namespace setting' do
              expect(setting.prevent_forking_outside_group?).to eq(true)
            end
          end
        end
      end
    end

    context 'without feature available' do
      before do
        setting.update!(prevent_forking_outside_group: true)
      end

      it 'returns false' do
        expect(setting.prevent_forking_outside_group?).to be_falsey
      end

      context 'when saml setting is available' do
        before do
          stub_licensed_features(group_saml: true)
        end

        context 'when it is configured to true on saml level' do
          before do
            create(:saml_provider, :enforced_group_managed_accounts, prohibited_outer_forks: true, group: group)
          end

          it 'returns true' do
            expect(setting.prevent_forking_outside_group?).to eq(true)
          end
        end

        context 'when it is configured to false on saml level' do
          before do
            create(:saml_provider, :enforced_group_managed_accounts, prohibited_outer_forks: false, group: group)
          end

          it 'returns false' do
            expect(setting.prevent_forking_outside_group?).to eq(false)
          end
        end
      end
    end
  end

  describe '#delayed_project_removal' do
    context 'when delayed deletion is enabled at the instance level' do
      before do
        stub_application_setting(deletion_adjourned_period: 7)
      end

      it 'defaults to true' do
        group

        expect(setting[:delayed_project_removal]).to eq(true)
      end

      context 'on a sub-group' do
        it 'defaults to nil' do
          subgroup = create(:group, parent: group)

          expect(subgroup.namespace_settings[:delayed_project_removal]).to be_nil
        end
      end

      context 'when providing a specific value' do
        let(:group) { create(:group, namespace_settings: build(:namespace_settings, delayed_project_removal: false)) }

        it 'saves the given value' do
          expect(setting[:delayed_project_removal]).to eq(false)
        end
      end
    end

    context 'when delayed deletion is disabled at the instance level' do
      before do
        stub_application_setting(deletion_adjourned_period: 0)
      end

      it 'defaults to nil' do
        group

        expect(setting[:delayed_project_removal]).to be_nil
      end
    end
  end
end
