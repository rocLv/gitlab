import { objectToQuery } from '~/lib/utils/url_utility';
import {
  MSG_ISSUES_ASSIGNED_TO_ME,
  MSG_ISSUES_IVE_CREATED,
  MSG_MR_ASSIGNED_TO_ME,
  MSG_MR_IM_REVIEWER,
  MSG_MR_IVE_CREATED,
  MSG_IN_ALL_GITLAB,
  MSG_IN_GROUP,
  MSG_IN_PROJECT,
} from '../constants';

export const searchQuery = (state) => {
  const query = {
    search: state.search,
    nav_source: 'navbar',
    project_id: state.searchContext.project?.id,
    group_id: state.searchContext.group?.id,
    scope: state.searchContext.scope,
  };

  return `${state.searchPath}?${objectToQuery(query)}`;
};

export const autocompleteQuery = (state) => {
  const query = {
    term: state.search,
    project_id: state.searchContext.project ? state.searchContext.project.id : null,
    ref: state.searchContext.ref ? state.searchContext.ref : null,
  };

  return `${state.autocompletePath}?${objectToQuery(query)}`;
};

export const scopedIssuesPath = (state) => {
  if (state.searchContext.project) {
    return state.searchContext.project_metadata.issues_path;
  }

  if (state.searchContext.group) {
    return state.searchContext.group_metadata.issues_path;
  }

  return state.issuesPath;
};

export const scopedMRPath = (state) => {
  if (state.searchContext.project) {
    return state.searchContext.project_metadata.mr_path;
  }

  if (state.searchContext.group) {
    return state.searchContext.group_metadata.mr_path;
  }

  return state.mrPath;
};

export const projectUrl = (state) => {
  if (!state.searchContext.project || !state.searchContext.group) {
    return null;
  }

  const query = {
    search: state.search,
    nav_source: 'navbar',
    project_id: state.searchContext.project.id,
    group_id: state.searchContext.group.id,
    scope: state.searchContext.scope,
  };

  return `${state.searchPath}?${objectToQuery(query)}`;
};

export const groupUrl = (state) => {
  if (!state.searchContext.group) {
    return null;
  }

  const query = {
    search: state.search,
    nav_source: 'navbar',
    group_id: state.searchContext.group.id,
    scope: state.searchContext.scope,
  };

  return `${state.searchPath}?${objectToQuery(query)}`;
};

export const allUrl = (state) => {
  const query = {
    search: state.search,
    nav_source: 'navbar',
    scope: state.searchContext.scope,
  };

  return `${state.searchPath}?${objectToQuery(query)}`;
};

export const defaultSearchOptions = (state, getters) => {
  const userName = gon.current_username;

  return [
    {
      title: MSG_ISSUES_ASSIGNED_TO_ME,
      url: `${getters.scopedIssuesPath}/?assignee_username=${userName}`,
    },
    {
      title: MSG_ISSUES_IVE_CREATED,
      url: `${getters.scopedIssuesPath}/?author_username=${userName}`,
    },
    {
      title: MSG_MR_ASSIGNED_TO_ME,
      url: `${getters.scopedMRPath}/?assignee_username=${userName}`,
    },
    {
      title: MSG_MR_IM_REVIEWER,
      url: `${getters.scopedMRPath}/?reviewer_username=${userName}`,
    },
    {
      title: MSG_MR_IVE_CREATED,
      url: `${getters.scopedMRPath}/?author_username=${userName}`,
    },
  ];
};

export const scopedSearchOptions = (state, getters) => {
  const options = [];

  if (state.searchContext.project) {
    options.push({
      scope: state.searchContext.project.name,
      description: MSG_IN_PROJECT,
      url: getters.projectUrl,
    });
  }

  if (state.searchContext.group) {
    options.push({
      scope: state.searchContext.group.name,
      description: MSG_IN_GROUP,
      url: getters.groupUrl,
    });
  }

  options.push({
    description: MSG_IN_ALL_GITLAB,
    url: getters.allUrl,
  });

  return options;
};

export const autocompleteSearchOptions = (state) => {
  const groupedOptions = [];

  state.autocompleteOptions.forEach((option) => {
    const existingCategory = groupedOptions.find(({ category }) => category === option.category);

    if (existingCategory) {
      existingCategory.data.push(option);
    } else {
      groupedOptions.push({
        category: option.category,
        data: [option],
      });
    }
  });

  return groupedOptions;
};

export const searchOptionsLength = (state, getters) => {
  if (!state.search) {
    return getters.defaultSearchOptions.length;
  }

  // We use state.autocompleteOptions as that is the raw list of options and not grouped
  return getters.scopedSearchOptions.length + state.autocompleteOptions.length;
};
