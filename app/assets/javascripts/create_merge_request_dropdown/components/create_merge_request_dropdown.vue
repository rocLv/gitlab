<script>
import { GlDropdown, GlDropdownItem, GlDropdownDivider } from '@gitlab/ui';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import DropdownForm from './dropdown_form.vue';

export const i18n = {
  checkingBranchAvailability: __('Checking branch availability…'),
  createBranch: __('Create branch'),
  createMergeRequest: __('Create merge request'),
  createMergeRequestAndBranch: __('Create merge request and branch'),
  createConfidentialMergeRequest: __('Create confidential merge request'),
  createConfidentialMergeRequestAndBranch: __('Create confidential merge request and branch'),
};

const CREATE_CONFIDENTIAL_MR = 'create-confidential-mr';
const CREATE_MR = 'create-mr';
const CREATE_BRANCH = 'create-branch';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    DropdownForm,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
    canCreateMergeRequest: {
      type: Boolean,
      required: true,
    },
    canCreateConfidentialMergeRequest: {
      type: Boolean,
      required: true,
    },
    canCreatePath: {
      type: String,
      required: true,
    },
    createMrPath: {
      type: String,
      required: true,
    },
    createBranchPath: {
      type: String,
      required: true,
    },
    refsPath: {
      type: String,
      required: true,
    },
    isConfidentialIssue: {
      type: Boolean,
      required: true,
    },
    projectDefaultBranch: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      loading: true,
      canCreateBranch: false,
      branch: '',
      source: this.projectDefaultBranch,
      canSubmit: true,
      selectedItemId: null,
    };
  },
  computed: {
    buttonText() {
      if (this.loading) {
        return i18n.checkingBranchAvailability;
      }

      return this.selectedItem.buttonText;
    },
    show() {
      return this.loading || this.canCreateBranch;
    },
    dropdownItems() {
      const branchItem = {
        id: CREATE_BRANCH,
        text: i18n.createBranch,
        buttonText: i18n.createBranch,
      };

      if (this.canCreateMergeRequest) {
        const mrItem = this.canCreateConfidentialMergeRequest
          ? {
              id: CREATE_CONFIDENTIAL_MR,
              text: i18n.createConfidentialMergeRequestAndBranch,
              buttonText: i18n.createConfidentialMergeRequest,
            }
          : {
              id: CREATE_MR,
              text: i18n.createMergeRequestAndBranch,
              buttonText: i18n.createMergeRequest,
            };

        return [mrItem, branchItem];
      }

      return [branchItem];
    },
    selectedItem: {
      get() {
        return this.selectedItemId
          ? this.dropdownItems.find((item) => item.id === this.selectedItemId)
          : this.dropdownItems[0];
      },

      set({ id }) {
        this.selectedItemId = id;
      },
    },
  },
  mounted() {
    this.checkAbilityToCreateBranch();
  },
  methods: {
    checkAbilityToCreateBranch() {
      this.loading = true;

      return axios
        .get(this.canCreatePath)
        .then(({ data }) => {
          if (data.can_create_branch) {
            this.branch = data.suggested_branch_name;
            this.canCreateBranch = true;
          }
        })
        .catch(() => {
          createFlash({
            message: __('Failed to check related branches.'),
          });
        })
        .finally(() => {
          this.loading = false;
        });
    },
    onClickItem(item) {
      this.selectedItem = item;
    },
    onFormChange({ branch, source, canSubmit }) {
      this.branch = branch;
      this.source = source;
      this.canSubmit = canSubmit;
    },
  },
  i18n,
};
</script>

<template>
  <gl-dropdown
    v-if="show"
    variant="confirm"
    :split="!isConfidentialIssue"
    right
    lazy
    :loading="loading"
    :text="buttonText"
  >
    <gl-dropdown-item
      v-for="item in dropdownItems"
      :key="item.id"
      is-check-item
      :is-checked="item.id === selectedItem.id"
      @click.native.capture.stop="onClickItem(item)"
    >
      {{ item.text }}
    </gl-dropdown-item>
    <gl-dropdown-divider />
    <dropdown-form
      :button-text="selectedItem.buttonText"
      :suggested-branch="branch"
      :suggested-source="source"
      :refs-path="refsPath"
      class="gl-px-3! gl-pt-3!"
      @change="onFormChange"
    />
  </gl-dropdown>
  <!--
  .create-mr-dropdown-wrap.d-inline-block.full-width-mobile.js-create-mr{ data: { project_path: @project.full_path, project_id: @project.id, can_create_path: can_create_path, create_mr_path: create_mr_path, create_branch_path: create_branch_path, refs_path: refs_path, is_confidential: can_create_confidential_merge_request?.to_s } }
    .btn-group.unavailable
      %button.gl-button.btn{ type: 'button', disabled: 'disabled' }
        .gl-spinner.align-text-bottom.gl-button-icon.hide
        %span.text
          Checking branch availability…

    .btn-group.available.hidden
      %button.gl-button.btn.js-create-merge-request.btn-confirm{ type: 'button', data: { action: data_action } }
        .gl-spinner.js-spinner.gl-mr-2.gl-display-none
        = value

      %button.gl-button.btn.btn-confirm.btn-icon.dropdown-toggle.create-merge-request-dropdown-toggle.js-dropdown-toggle{ type: 'button', data: { dropdown: { trigger: '#create-merge-request-dropdown' }, display: 'static' } }
        = sprite_icon('chevron-down')

      .droplab-dropdown
        %ul#create-merge-request-dropdown.create-merge-request-dropdown-menu.dropdown-menu.dropdown-menu-right.gl-show-field-errors{ class: ("create-confidential-merge-request-dropdown-menu" if can_create_confidential_merge_request?), data: { dropdown: true } }
          - if can_create_merge_request
            %li.droplab-item-selected{ role: 'button', data: { value: 'create-mr', text: create_mr_text } }
              .menu-item.text-nowrap
                = sprite_icon('check', css_class: 'icon')
                - if can_create_confidential_merge_request?
                  = _('Create confidential merge request and branch')
                - else
                  = _('Create merge request and branch')

          %li{ class: [!can_create_merge_request && 'droplab-item-selected'], role: 'button', data: { value: 'create-branch', text: _('Create branch') } }
            .menu-item
              = sprite_icon('check', css_class: 'icon')
              = _('Create branch')
          %li.divider.droplab-item-ignore

          %li.droplab-item-ignore.gl-ml-3.gl-mr-3.gl-mt-5
            - if can_create_confidential_merge_request?
              #js-forked-project{ data: { namespace_path: @project.namespace.full_path, project_path: @project.full_path, new_fork_path: new_project_fork_path(@project), help_page_path: help_page_path('user/project/merge_requests/index.md') } }
            .form-group
              %label{ for: 'new-branch-name' }
                = _('Branch name')
              %input#new-branch-name.js-branch-name.form-control.gl-form-input{ type: 'text', placeholder: "#{@issue.to_branch_name}", value: "#{@issue.to_branch_name}" }
              %span.js-branch-message.form-text

            .form-group
              %label{ for: 'source-name' }
                = _('Source (branch or tag)')
              %input#source-name.js-ref.ref.form-control.gl-form-input{ type: 'text', placeholder: "#{@project.default_branch}", value: "#{@project.default_branch}", data: { value: "#{@project.default_branch}" } }
              %span.js-ref-message.form-text.text-muted

            .form-group
              %button.btn.gl-button.btn-confirm.js-create-target{ type: 'button', data: { action: 'create-mr' } }
                = create_mr_text

            - if can_create_confidential_merge_request?
              %p.text-warning.js-exposed-info-warning.hidden
                = _('This may expose confidential information as the selected fork is in another namespace that can have other members.')
  -->
</template>

<style>
.dropdown-menu {
  max-height: none;
}

.gl-new-dropdown-inner {
  max-height: none;
  font-feature-settings: 'smcp', 'zero';
}
</style>
