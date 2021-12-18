import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import OrganizationsRoot from '~/crm/components/organizations_root.vue';
import OrganizationForm from '~/crm/components/form.vue';
import { NEW_ROUTE_NAME, EDIT_ROUTE_NAME } from '~/crm/constants';
import routes from '~/crm/routes';
import getGroupOrganizationsQuery from '~/crm/components/queries/get_group_organizations.query.graphql';
import { getGroupOrganizationsQueryResponse } from './mock_data';

describe('Customer relations organizations root app', () => {
  Vue.use(VueApollo);
  Vue.use(VueRouter);
  let wrapper;
  let fakeApollo;
  let router;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findRowByName = (rowName) => wrapper.findAllByRole('row', { name: rowName });
  const findIssuesLinks = () => wrapper.findAllByTestId('issues-link');
  const findNewOrganizationButton = () => wrapper.findByTestId('new-organization-button');
  const findEditOrganizationButton = () => wrapper.findByTestId('edit-organization-button');
  const findOrganizationForm = () => wrapper.findComponent(OrganizationForm);
  const findError = () => wrapper.findComponent(GlAlert);
  const successQueryHandler = jest.fn().mockResolvedValue(getGroupOrganizationsQueryResponse);

  const basePath = '/groups/flightjs/-/crm/organizations';

  const mountComponent = ({
    queryHandler = successQueryHandler,
    mountFunction = shallowMountExtended,
    canAdminCrmOrganization = true,
  } = {}) => {
    fakeApollo = createMockApollo([[getGroupOrganizationsQuery, queryHandler]]);
    wrapper = mountFunction(OrganizationsRoot, {
      router,
      provide: {
        canAdminCrmOrganization,
        groupFullPath: 'flightjs',
        groupId: 26,
        groupIssuesPath: '/issues',
      },
      apolloProvider: fakeApollo,
    });
  };

  beforeEach(() => {
    router = new VueRouter({
      base: basePath,
      mode: 'history',
      routes,
    });
  });

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
    router = null;
  });

  it('should render loading spinner', () => {
    mountComponent();

    expect(findLoadingIcon().exists()).toBe(true);
  });

  describe('new organization button', () => {
    it('should exist when user has permission', () => {
      mountComponent();

      expect(findNewOrganizationButton().exists()).toBe(true);
    });

    it('should not exist when user has no permission', () => {
      mountComponent({ canAdminCrmOrganization: false });

      expect(findNewOrganizationButton().exists()).toBe(false);
    });
  });

  describe('organization form', () => {
    it('should not exist by default', async () => {
      mountComponent({ mountFunction: mountExtended });
      await waitForPromises();

      expect(findOrganizationForm().exists()).toBe(false);
    });

    it('should exist when user clicks new contact button', async () => {
      mountComponent({ mountFunction: mountExtended });
      await waitForPromises();

      findNewOrganizationButton().vm.$emit('click');
      await waitForPromises();

      expect(findOrganizationForm().exists()).toBe(true);
    });

    it('should exist when user navigates directly to `new` route', async () => {
      router.replace({ name: NEW_ROUTE_NAME });
      mountComponent({ mountFunction: mountExtended });
      await waitForPromises();

      expect(findOrganizationForm().exists()).toBe(true);
    });

    it('should exist when user clicks edit organization button', async () => {
      mountComponent({ mountFunction: mountExtended });
      await waitForPromises();

      findEditOrganizationButton().vm.$emit('click');
      await waitForPromises();

      expect(findOrganizationForm().exists()).toBe(true);
    });

    it('should exist when user navigates directly to `edit` route', async () => {
      router.replace({ name: EDIT_ROUTE_NAME, params: { id: 2 } });
      mountComponent({ mountFunction: mountExtended });
      await waitForPromises();

      expect(findOrganizationForm().exists()).toBe(true);
    });

    it('should not exist when new form emits close', async () => {
      router.replace({ name: NEW_ROUTE_NAME });
      mountComponent({ mountFunction: mountExtended });
      await waitForPromises();

      findOrganizationForm().vm.$emit('close');
      await waitForPromises();

      expect(findOrganizationForm().exists()).toBe(false);
    });

    it('should not exist when edit form emits close', async () => {
      router.replace({ name: EDIT_ROUTE_NAME, params: { id: 2 } });
      mountComponent({ mountFunction: mountExtended });
      await waitForPromises();

      findOrganizationForm().vm.$emit('close');
      await waitForPromises();

      expect(findOrganizationForm().exists()).toBe(false);
    });
  });

  it('should render error message on reject', async () => {
    mountComponent({ queryHandler: jest.fn().mockRejectedValue('ERROR') });
    await waitForPromises();

    expect(findError().exists()).toBe(true);
  });

  describe('on successful load', () => {
    it('should not render error', async () => {
      mountComponent();
      await waitForPromises();

      expect(findError().exists()).toBe(false);
    });

    it('renders correct results', async () => {
      mountComponent({ mountFunction: mountExtended });
      await waitForPromises();

      expect(findRowByName(/Test Inc/i)).toHaveLength(1);
      expect(findRowByName(/VIP/i)).toHaveLength(1);
      expect(findRowByName(/120/i)).toHaveLength(1);

      const issueLink = findIssuesLinks().at(0);
      expect(issueLink.exists()).toBe(true);
      expect(issueLink.attributes('href')).toBe(
        '/issues?scope=all&state=opened&crm_organization_id=2',
      );
    });
  });
});
