import { GlButton, GlForm } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import TrialCreateLeadForm from 'ee/trials/components/trial_create_lead_form.vue';
import { TRIAL_FORM_SUBMIT_TEXT } from 'ee/trials/constants';
import { trackSaasTrialSubmit } from '~/google_tag_manager';
import { formData, submitPath } from './mock_data';

jest.mock('~/google_tag_manager', () => ({
  trackSaasTrialSubmit: jest.fn(),
}));

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('TrialCreateLeadForm', () => {
  let wrapper;

  const createComponent = ({ mountFunction = shallowMountExtended } = {}) => {
    const mockResolvers = {
      Query: {
        countries() {
          return [{ id: 'US', name: 'United States' }];
        },
      },
    };

    return mountFunction(TrialCreateLeadForm, {
      localVue,
      apolloProvider: createMockApollo([], mockResolvers),
      provide: {
        submitPath,
        user: formData,
      },
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findButton = () => wrapper.findComponent(GlButton);
  const findFormInput = (testId) => wrapper.findByTestId(testId);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('has the "Continue" text on the submit button', () => {
      expect(findButton().text()).toBe(TRIAL_FORM_SUBMIT_TEXT);
    });

    it.each`
      testid            | value
      ${'first_name'}   | ${'Joe'}
      ${'last_name'}    | ${'Doe'}
      ${'company_name'} | ${'ACME'}
      ${'phone_number'} | ${'192919'}
      ${'company_size'} | ${'1-99'}
      ${'country'}      | ${'US'}
    `('has the default injected value for $testid', ({ testid, value }) => {
      expect(findFormInput(testid).attributes('value')).toBe(value);
    });

    it('has the correct form input in the form content', () => {
      const visibleFields = [
        'first_name',
        'last_name',
        'company_name',
        'company_size',
        'phone_number',
        'country',
      ];

      visibleFields.forEach((f) => expect(wrapper.findByTestId(f).exists()).toBe(true));
    });
  });

  describe('submitting', () => {
    beforeEach(() => {
      wrapper = createComponent({ mountFunction: mountExtended });
    });

    it('tracks the saas Trial', () => {
      findForm().trigger('submit');

      expect(trackSaasTrialSubmit).toHaveBeenCalled();
    });
  });
});
