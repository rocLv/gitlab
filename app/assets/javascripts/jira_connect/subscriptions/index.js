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
  const { groups_path: groupsPath, subscriptions_path: subscriptionsPath } = JSON.parse(
    oauthMetadata,
  );
  const store = createStore();

  await updateSignInLinks();
  setConfigs();
  sizeToParent();

  Vue.use(Translate);
  Vue.use(GlFeatureFlagsPlugin);

  return new Vue({
    el,
    store,
    provide: {
      oauthMetadata: JSON.parse(oauthMetadata),
      groupsPath,
      subscriptionsPath,
    },
    render(createElement) {
      return createElement(JiraConnectAppOauth);
    },
  });
}

async function initJiraConnectLegacy(el) {
  const { groupsPath, subscriptions, subscriptionsPath, usersPath } = el.dataset;
  const store = createStore();

  await updateSignInLinks();
  setConfigs();
  sizeToParent();

  Vue.use(Translate);
  Vue.use(GlFeatureFlagsPlugin);

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

function initJiraConnect() {
  const jiraConnectLegacyEl = document.querySelector('.js-jira-connect-app');
  const jiraConnectOAuthEl = document.querySelector('.js-jira-connect-app-oauth');

  if (jiraConnectLegacyEl) {
    initJiraConnectLegacy(jiraConnectLegacyEl);
  } else if (jiraConnectOAuthEl) {
    initJiraConnectWithOAuth(jiraConnectOAuthEl);
  }
}

document.addEventListener('DOMContentLoaded', initJiraConnect);
