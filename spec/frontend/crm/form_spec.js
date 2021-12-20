import { GlAlert } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Form from '~/crm/components/form.vue';
import createContactMutation from '~/crm/components/queries/create_contact.mutation.graphql';
import updateContactMutation from '~/crm/components/queries/update_contact.mutation.graphql';
import getGroupContactsQuery from '~/crm/components/queries/get_group_contacts.query.graphql';
import {
  createContactMutationErrorResponse,
  createContactMutationResponse,
  getGroupContactsQueryResponse,
  updateContactMutationErrorResponse,
  updateContactMutationResponse,
} from './mock_data';

describe('Reusable form component', () => {
  Vue.use(VueApollo);
  let wrapper;
  let queryHandler;

  const mockToastShow = jest.fn();

  const findSaveButton = () => wrapper.findByTestId('save-button');
  const findForm = () => wrapper.find('form');
  const findError = () => wrapper.findComponent(GlAlert);

  const mountContactCreate = () => {
    if (!queryHandler) queryHandler = jest.fn().mockResolvedValue(createContactMutationResponse);
    const fakeApollo = createMockApollo([[createContactMutation, queryHandler]]);

    const propsData = {
      getQuery: getGroupContactsQuery,
      getQueryVariables: { groupFullPath: 'flightjs' },
      getQueryNodePath: 'group.contacts',
      createMutation: createContactMutation,
      additionalCreateParams: { groupId: 'gid://gitlab/Group/26' },
    };
    mountContact({ propsData, fakeApollo });
  };

  const mountContactUpdate = () => {
    if (!queryHandler) queryHandler = jest.fn().mockResolvedValue(updateContactMutationResponse);
    const fakeApollo = createMockApollo([[updateContactMutation, queryHandler]]);

    const propsData = {
      updateMutation: updateContactMutation,
      existingModel: {
        id: 'gid://gitlab/CustomerRelations::Contact/12',
        firstName: 'First',
        lastName: 'Last',
        email: 'email@example.com',
      },
      isEditMode: true,
    };
    mountContact({ propsData, fakeApollo });
  };

  const mountContact = ({ propsData, fakeApollo } = {}) => {
    fakeApollo.clients.defaultClient.cache.writeQuery({
      query: getGroupContactsQuery,
      variables: { groupFullPath: 'flightjs' },
      data: getGroupContactsQueryResponse.data,
    });
    mountComponent(
      {
        fields: [
          { name: 'firstName', label: 'First name', required: true },
          { name: 'lastName', label: 'Last name', required: true },
          { name: 'email', label: 'Email', required: true },
          { name: 'phone', label: 'Phone' },
          { name: 'description', label: 'Description' },
        ],
        ...propsData,
      },
      fakeApollo,
    );
  };

  const mountComponent = (propsData, fakeApollo) => {
    wrapper = shallowMountExtended(Form, {
      apolloProvider: fakeApollo,
      propsData: { drawerOpen: true, i18n: { modelName: 'Contact' }, ...propsData },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  const formNames = {
    createContact: 'create contact',
    updateContact: 'update contact',
    createOrganization: 'create organization',
    updateOrganization: 'update organization',
  };

  const mountFunctions = {};
  mountFunctions[formNames.createContact] = mountContactCreate;
  mountFunctions[formNames.updateContact] = mountContactUpdate;

  const mutationErrorResponses = {};
  mutationErrorResponses[formNames.createContact] = createContactMutationErrorResponse;
  mutationErrorResponses[formNames.updateContact] = updateContactMutationErrorResponse;

  afterEach(() => {
    wrapper.destroy();
    queryHandler = null;
  });

  describe.each([formNames.createContact, formNames.updateContact])(
    '%s form save button',
    (formName) => {
      beforeEach(() => {
        mountFunctions[formName]();
      });

      it('should be disabled when required fields are empty', async () => {
        wrapper.find('#firstName').vm.$emit('input', '');
        await waitForPromises();

        expect(findSaveButton().props('disabled')).toBe(true);
      });

      it('should not be disabled when required fields have values', async () => {
        wrapper.find('#firstName').vm.$emit('input', 'A');
        wrapper.find('#lastName').vm.$emit('input', 'B');
        wrapper.find('#email').vm.$emit('input', 'C');
        await waitForPromises();

        expect(findSaveButton().props('disabled')).toBe(false);
      });
    },
  );

  describe('when mutation is successful', () => {
    it('create form should display correct toast message', async () => {
      mountContactCreate();

      findForm().trigger('submit');
      await waitForPromises();

      expect(mockToastShow).toHaveBeenCalledWith('Contact has been added');
    });

    it('update form should display correct toast message', async () => {
      mountContactUpdate();

      findForm().trigger('submit');
      await waitForPromises();

      expect(mockToastShow).toHaveBeenCalledWith('Contact has been updated');
    });
  });

  describe.each([formNames.createContact, formNames.updateContact])(
    'when %s mutation fails',
    (formName) => {
      it('should show error on reject', async () => {
        queryHandler = jest.fn().mockRejectedValue('ERROR');
        mountFunctions[formName]();

        findForm().trigger('submit');
        await waitForPromises();

        expect(findError().text()).toBe('Something went wrong. Please try again.');
      });

      it('should show error on error response', async () => {
        queryHandler = jest.fn().mockResolvedValue(mutationErrorResponses[formName]);
        mountFunctions[formName]();

        findForm().trigger('submit');
        await waitForPromises();

        expect(findError().text()).toBe(`${formName} is invalid.`);
      });
    },
  );
});
