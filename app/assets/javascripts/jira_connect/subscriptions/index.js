import '../../webpack';

import setConfigs from '@gitlab/ui/dist/config';
import Vue from 'vue';
import GlFeatureFlagsPlugin from '~/vue_shared/gl_feature_flags_plugin';
import Translate from '~/vue_shared/translate';

import JiraConnectAppLegacy from './pages/app_legacy.vue';
import JiraConnectAppOauth from './pages/app_oauth.vue';
import createStore from './store';
import { getLocation, sizeToParent } from './utils';

const updateSignInLinks = async () => {
  const location = await getLocation();
  Array.from(document.querySelectorAll('.js-jira-connect-sign-in')).forEach((el) => {
    const updatedLink = `${el.getAttribute('href')}?return_to=${location}`;
    el.setAttribute('href', updatedLink);
  });
};

async function initJiraConnectWithOAuth(el) {
  const { oauthMetadata } = el.dataset;
  const store = createStore();

  setConfigs();
  sizeToParent();

  Vue.use(Translate);
  Vue.use(GlFeatureFlagsPlugin);

  return new Vue({
    el,
    store,
    provide: {
      oauthMetadata: JSON.parse(oauthMetadata),
    },
    render(createElement) {
      return createElement(JiraConnectAppOauth);
    },
  });
}

async function initJiraConnectLegacy(el) {
  setConfigs();
  Vue.use(Translate);
  Vue.use(GlFeatureFlagsPlugin);

  const { groupsPath, subscriptions, subscriptionsPath, usersPath } = el.dataset;
  sizeToParent();
  const store = createStore();

  return new Vue({
    el,
    store,
    provide: {
      groupsPath,
      subscriptions: JSON.parse(subscriptions),
      subscriptionsPath,
      usersPath,
    },
    render(createElement) {
      return createElement(JiraConnectAppLegacy);
    },
  });
}

export async function initJiraConnect() {
  await updateSignInLinks();

  const jiraConnectLegacyEl = document.querySelector('.js-jira-connect-app');
  const jiraConnectOAuthEl = document.querySelector('.js-jira-connect-app-oauth');

  if (jiraConnectLegacyEl) {
    initJiraConnectLegacy(jiraConnectLegacyEl);
  } else if (jiraConnectOAuthEl) {
    initJiraConnectWithOAuth(jiraConnectOAuthEl);
  }
}

document.addEventListener('DOMContentLoaded', initJiraConnect);
