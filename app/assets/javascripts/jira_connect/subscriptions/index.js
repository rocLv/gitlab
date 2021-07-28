import '../../webpack';

import setConfigs from '@gitlab/ui/dist/config';
import Vue from 'vue';
import GlFeatureFlagsPlugin from '~/vue_shared/gl_feature_flags_plugin';
import Translate from '~/vue_shared/translate';

import JiraConnectApp from './components/app.vue';
import createStore from './store';
import { getLocation, sizeToParent } from './utils';
import axios from '~/lib/utils/axios_utils';


const store = createStore();

const updateSignInLinks = async () => {
  const location = await getLocation();
  Array.from(document.querySelectorAll('.js-jira-connect-sign-in')).forEach((el) => {
    const updatedLink = `${el.getAttribute('href')}?return_to=${location}`;
    el.setAttribute('href', updatedLink);
  });
};

const updateOauthLink = async () => {
  const location = await getLocation();
  Array.from(document.querySelectorAll('.js-jira-connect-oauth')).forEach((el) => {
    const updatedLink = `${el.getAttribute('href')}::${location}`;
    el.setAttribute('href', updatedLink);
  });
};

const getOAuthAuthentication = async () => {
  const location = await getLocation();

  const locationParsed = new URL(location);

  const code = locationParsed.searchParams.get('code');

  if(code){
    //try to oauth
    const oauth_stuff = JSON.parse(localStorage.getItem('oauth_stuff'));

    console.log('ANDY', code, oauth_stuff);

    //const { data } = await axios.post('oaut')
  }

  localStorage.setItem('oauth_stuff', JSON.stringify(document.querySelector('.oauth_metadata').dataset))


}

export async function initJiraConnect() {
  await updateSignInLinks();
  await updateOauthLink();

  const token = await getOAuthAuthentication();


  const el = document.querySelector('.js-jira-connect-app');
  if (!el) {
    return null;
  }

  setConfigs();
  Vue.use(Translate);
  Vue.use(GlFeatureFlagsPlugin);

  const { groupsPath, subscriptions, subscriptionsPath, usersPath } = el.dataset;
  sizeToParent();

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

document.addEventListener('DOMContentLoaded', initJiraConnect);
