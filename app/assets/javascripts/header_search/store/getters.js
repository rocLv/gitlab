import { objectToQuery } from '~/lib/utils/url_utility';

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
