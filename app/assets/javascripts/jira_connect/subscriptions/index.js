import '../../webpack';

import setConfigs from '@gitlab/ui/dist/config';
import Vue from 'vue';
import GlFeatureFlagsPlugin from '~/vue_shared/gl_feature_flags_plugin';
import Translate from '~/vue_shared/translate';

import JiraConnectApp from './components/app.vue';
import JiraOauthConnectApp from './components/oauth_app.vue';
import createStore from './store';
import { getLocation, sizeToParent } from './utils';

const getOAuthMetadata = () => {
  return JSON.parse(document.getElementById('oauth_metadata').textContent);
};

const updateSignInLinks = async () => {
  const location = await getLocation();
  Array.from(document.querySelectorAll('.js-jira-connect-sign-in')).forEach((el) => {
    const updatedLink = `${el.getAttribute('href')}?return_to=${location}`;
    el.setAttribute('href', updatedLink);
  });
};
export async function initJiraConnect() {
  await updateSignInLinks();

  setConfigs();
  Vue.use(Translate);
  Vue.use(GlFeatureFlagsPlugin);

  const el = document.querySelector('.js-jira-connect-app');
  if (el) {
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
        return createElement(JiraConnectApp);
      },
    });
  }

  const elNew = document.querySelector('.js-jira-connect-oauth-app');
  if (elNew) {
    // We probably want to add a store here as well. It could handle all the oAuth stuff.
    return new Vue({
      el: elNew,
      provide: {
        oauthConfig: getOAuthMetadata(),
      },
      render(createElement) {
        return createElement(JiraOauthConnectApp);
      },
    });
  }

  return null;
}

document.addEventListener('DOMContentLoaded', initJiraConnect);
