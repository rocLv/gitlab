import { shallowMount } from '@vue/test-utils';

import JiraConnectAppOauth from '~/jira_connect/subscriptions/pages/app_oauth.vue';
import SignInPage from '~/jira_connect/subscriptions/pages/sign_in.vue';
import SubscriptionsPage from '~/jira_connect/subscriptions/pages/subscriptions.vue';
import createStore from '~/jira_connect/subscriptions/store';

describe('JiraConnectAppOauth', () => {
  let wrapper;
  let store;

  const findSignInPage = () => wrapper.findComponent(SignInPage);
  const findSubscriptionsPage = () => wrapper.findComponent(SubscriptionsPage);

  const createComponent = ({ provide } = {}) => {
    store = createStore();

    wrapper = shallowMount(JiraConnectAppOauth, {
      store,
      provide,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders SignIn page by default', () => {
    createComponent();

    expect(findSignInPage().exists()).toBe(true);
    expect(findSubscriptionsPage().exists()).toBe(false);
  });

  describe('when SignIn page emits `sign-in` event', () => {
    it('renders the Subscriptions page', async () => {
      createComponent();

      const signInPage = findSignInPage();
      await signInPage.vm.$emit('sign-in', 'mock-user');

      expect(findSubscriptionsPage().exists()).toBe(true);
      expect(signInPage.exists()).toBe(false);
    });
  });
});
