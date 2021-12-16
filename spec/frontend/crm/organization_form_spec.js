import { GlAlert } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import OrganizationForm from '~/crm/components/organization_form.vue';
import createOrganizationMutation from '~/crm/components/queries/create_organization.mutation.graphql';
import updateOrganizationMutation from '~/crm/components/queries/update_organization.mutation.graphql';
import getGroupOrganizationsQuery from '~/crm/components/queries/get_group_organizations.query.graphql';
import {
  createOrganizationMutationErrorResponse,
  createOrganizationMutationResponse,
  getGroupOrganizationsQueryResponse,
  updateOrganizationMutationErrorResponse,
  updateOrganizationMutationResponse,
} from './mock_data';

describe('Customer relations organizations root app', () => {
  Vue.use(VueApollo);
  let wrapper;
  let fakeApollo;
  let mutation;
  let queryHandler;

  const findSaveOrganizationButton = () => wrapper.findByTestId('save-organization-button');
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findForm = () => wrapper.find('form');
  const findError = () => wrapper.findComponent(GlAlert);

  const mountComponent = ({ editForm = false } = {}) => {
    fakeApollo = createMockApollo([[mutation, queryHandler]]);
    fakeApollo.clients.defaultClient.cache.writeQuery({
      query: getGroupOrganizationsQuery,
      variables: { groupFullPath: 'flightjs' },
      data: getGroupOrganizationsQueryResponse.data,
    });

    const propsData = { drawerOpen: true };
    if (editForm) propsData.organization = { name: 'Company Inc' };

    wrapper = shallowMountExtended(OrganizationForm, {
      provide: { groupId: 26, groupFullPath: 'flightjs' },
      apolloProvider: fakeApollo,
      propsData,
    });
  };

  beforeEach(() => {
    mutation = createOrganizationMutation;
    queryHandler = jest.fn().mockResolvedValue(createOrganizationMutationResponse);
  });

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
  });

  describe('Save organization button', () => {
    it('should be disabled when required fields are empty', () => {
      mountComponent();

      expect(findSaveOrganizationButton().attributes('disabled')).toBeTruthy();
    });

    it('should not be disabled when required fields have values', async () => {
      mountComponent();

      wrapper.find('#organization-name').vm.$emit('input', 'A');
      await waitForPromises();

      expect(findSaveOrganizationButton().attributes('disabled')).toBeFalsy();
    });
  });

  it("should emit 'close' when cancel button is clicked", () => {
    mountComponent();

    findCancelButton().vm.$emit('click');

    expect(wrapper.emitted().close).toBeTruthy();
  });

  describe('when create mutation is successful', () => {
    it("should emit 'close'", async () => {
      mountComponent();

      findForm().trigger('submit');
      await waitForPromises();

      expect(wrapper.emitted().close).toBeTruthy();
    });
  });

  describe('when create mutation fails', () => {
    it('should show error on reject', async () => {
      queryHandler = jest.fn().mockRejectedValue('ERROR');
      mountComponent();

      findForm().trigger('submit');
      await waitForPromises();

      expect(findError().exists()).toBe(true);
    });

    it('should show error on error response', async () => {
      queryHandler = jest.fn().mockResolvedValue(createOrganizationMutationErrorResponse);
      mountComponent();

      findForm().trigger('submit');
      await waitForPromises();

      expect(findError().exists()).toBe(true);
      expect(findError().text()).toBe('Name cannot be blank.');
    });
  });

  describe('when update mutation is successful', () => {
    it("should emit 'close'", async () => {
      mutation = updateOrganizationMutation;
      queryHandler = jest.fn().mockResolvedValue(updateOrganizationMutationResponse);
      mountComponent({ editForm: true });

      findForm().trigger('submit');
      await waitForPromises();

      expect(wrapper.emitted().close).toBeTruthy();
    });
  });

  describe('when update mutation fails', () => {
    beforeEach(() => {
      mutation = updateOrganizationMutation;
    });

    it('should show error on reject', async () => {
      queryHandler = jest.fn().mockRejectedValue('ERROR');
      mountComponent({ editForm: true });
      findForm().trigger('submit');
      await waitForPromises();

      expect(findError().exists()).toBe(true);
    });

    it('should show error on error response', async () => {
      queryHandler = jest.fn().mockResolvedValue(updateOrganizationMutationErrorResponse);
      mountComponent({ editForm: true });

      findForm().trigger('submit');
      await waitForPromises();

      expect(findError().exists()).toBe(true);
      expect(findError().text()).toBe('Description is invalid.');
    });
  });
});
