import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import CreateMergeRequestDropdown from './components/create_merge_request_dropdown.vue';

export const initCreateMergeRequestDropdown = () => {
  const el = document.querySelector('#js-create-mr-dropdown');

  if (!el) {
    return null;
  }

  const {
    projectPath,
    projectId,
    canCreateMergeRequest,
    canCreateConfidentialMergeRequest,
    canCreatePath,
    createMrPath,
    createBranchPath,
    projectDefaultBranch,
    refsPath,
    isConfidentialIssue,
  } = el.dataset;

  return new Vue({
    el,
    render(h) {
      return h(CreateMergeRequestDropdown, {
        props: {
          projectPath,
          projectId,
          canCreateMergeRequest: parseBoolean(canCreateMergeRequest),
          canCreateConfidentialMergeRequest: parseBoolean(canCreateConfidentialMergeRequest),
          canCreatePath,
          createMrPath,
          createBranchPath,
          projectDefaultBranch,
          refsPath,
          isConfidentialIssue: parseBoolean(isConfidentialIssue),
        },
      });
    },
  });
};
