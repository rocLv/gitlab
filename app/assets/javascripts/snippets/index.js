import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

import { SNIPPET_LEVELS_MAP, SNIPPET_VISIBILITY_PRIVATE } from '~/snippets/constants';
import Translate from '~/vue_shared/translate';

import Tabs from './components/tabs.vue';

Vue.use(VueApollo);
Vue.use(Translate);

export const initSnippetsTabs = () => {
  const el = document.querySelector('#js-snippets-tabs');

  const { tabs } = el.dataset;

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    provide: {
      tabs: JSON.parse(tabs),
    },
    render(createElement) {
      return createElement(Tabs);
    },
  });
};

export default function appFactory(el, Component) {
  if (!el) {
    return false;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(
      {},
      {
        batchMax: 1,
      },
    ),
  });

  const {
    visibilityLevels = '[]',
    selectedLevel,
    multipleLevelsRestricted,
    canReportSpam,
    reportAbusePath,
    ...restDataset
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      visibilityLevels: JSON.parse(visibilityLevels),
      selectedLevel: SNIPPET_LEVELS_MAP[selectedLevel] ?? SNIPPET_VISIBILITY_PRIVATE,
      multipleLevelsRestricted: 'multipleLevelsRestricted' in el.dataset,
      reportAbusePath,
      canReportSpam,
    },
    render(createElement) {
      return createElement(Component, {
        props: {
          ...restDataset,
        },
      });
    },
  });
}
