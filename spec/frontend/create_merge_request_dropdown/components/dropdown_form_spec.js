import { GlFormGroup } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { stubComponent } from 'helpers/stub_component';
import DropdownForm, { i18n } from '~/create_merge_request_dropdown/components/dropdown_form.vue';
import axios from '~/lib/utils/axios_utils';

const defaultProps = {
  buttonText: 'buttonTextProp',
  suggestedBranch: '123-a-branch',
  suggestedSource: 'main',
  refsPath: '/gitlab-org/gitlab/refs?search=',
};

describe('DropdownForm component', () => {
  let wrapper;
  let mockAxios;

  const createComponent = (props) => {
    wrapper = mount(DropdownForm, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlFormGroup: stubComponent(GlFormGroup, {
          props: ['state', 'invalidFeedback', 'validFeedback', 'description'],
        }),
      },
    });
  };

  const findForm = () => wrapper.find('form');
  const findBranchInput = () => wrapper.find('input[name="branch"]');
  const findSourceInput = () => wrapper.find('input[name="source"]');
  const findBranchFormGroup = () => wrapper.findAllComponents(GlFormGroup).at(0);
  const findSourceFormGroup = () => wrapper.findAllComponents(GlFormGroup).at(1);
  const findSubmitButton = () => wrapper.find('button[type="submit"]');

  const branchValidation = () => {
    const formGroup = findBranchFormGroup();
    const state = formGroup.props('state');

    const textForState = new Map([
      [true, formGroup.props('validFeedback')],
      [false, formGroup.props('invalidFeedback')],
      [null, formGroup.props('description')],
    ]);

    return {
      state,
      text: textForState.get(state),
    };
  };

  const sourceValidation = () => {
    const formGroup = findSourceFormGroup();
    const state = formGroup.props('state');

    const textForState = new Map([
      [true, formGroup.props('validFeedback')],
      [false, formGroup.props('invalidFeedback')],
      [null, formGroup.props('description')],
    ]);

    return {
      state,
      text: textForState.get(state),
    };
  };

  const mockRefEndpoint = ({ search, expectMatches = true, fail = false, delay = 0 }) => {
    mockAxios = new MockAdapter(axios, { delayResponse: delay });

    if (fail) {
      // Return 404 on all requests
      return;
    }

    mockAxios
      .onGet(`${defaultProps.refsPath}${encodeURIComponent(search)}`)
      .reply(
        200,
        expectMatches
          ? { Branches: [search, `123-${search}`], Tags: [`v1.0-${search}`, `v2.0-${search}`] }
          : { Branches: [], Tags: [] },
      );
  };

  const waitForDebouncedRequests = () => {
    jest.runOnlyPendingTimers();
    return axios.waitForAll();
  };

  afterEach(() => {
    wrapper.destroy();

    if (mockAxios) {
      mockAxios.restore();
    }
  });

  describe('initial render', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets the branch input value', () => {
      expect(findBranchInput().element.value).toBe(defaultProps.suggestedBranch);
    });

    it('sets the source input value', () => {
      expect(findSourceInput().element.value).toBe(defaultProps.suggestedSource);
    });
  });

  describe('submitting the form', () => {
    beforeEach(() => {
      createComponent();
      findForm().trigger('submit');
    });

    it('emits a submit event', () => {
      expect(wrapper.emitted('submit')).toEqual([[]]);
    });
  });

  describe('changing the branch input', () => {
    const search = 'foobar';

    beforeEach(() => {
      mockRefEndpoint({ search, delay: 1 });

      createComponent();
      findBranchInput().setValue(search);
    });

    it('emits a change event', () => {
      expect(wrapper.emitted('change')).toEqual([
        [
          {
            branch: search,
            source: defaultProps.suggestedSource,
            canSubmit: false,
          },
        ],
      ]);
    });

    it('renders a loading state', () => {
      expect(branchValidation()).toEqual({
        text: i18n.checkingBranch,
        state: null,
      });
    });
  });

  describe('clearing the branch input', () => {
    beforeEach(() => {
      mockRefEndpoint({ delay: 1 });

      createComponent();
      findBranchInput().setValue('');
    });

    it('does not send a request', () => {
      expect(mockAxios.history.get).toEqual([]);
    });

    it('emits a change event with the suggested branch', () => {
      expect(wrapper.emitted('change')).toEqual([
        [
          {
            branch: defaultProps.suggestedBranch,
            source: defaultProps.suggestedSource,
            canSubmit: true,
          },
        ],
      ]);
    });
  });

  describe('given a branch that does not exist yet', () => {
    const search = 'foobar';

    beforeEach(() => {
      mockRefEndpoint({ search, expectMatches: false });

      createComponent();
      findBranchInput().setValue(search);

      return waitForDebouncedRequests();
    });

    it('emits a change event', async () => {
      expect(wrapper.emitted('change')).toHaveLength(2);

      // The first change event was for the initial input, but the second is
      // for the successful validation of the input.
      expect(wrapper.emitted('change')[1]).toEqual([
        {
          branch: search,
          source: defaultProps.suggestedSource,
          canSubmit: true,
        },
      ]);
    });

    it('renders a valid state', () => {
      expect(branchValidation()).toEqual({
        text: i18n.branchAvailable,
        state: true,
      });
    });

    it('does not disable the submit button', () => {
      expect(findSubmitButton().attributes('disabled')).toBe(undefined);
    });
  });

  describe('given the branch already exists', () => {
    const search = 'main';

    beforeEach(() => {
      mockRefEndpoint({ search });

      createComponent();
      findBranchInput().setValue(search);

      return waitForDebouncedRequests();
    });

    it('emits a change event', async () => {
      expect(wrapper.emitted('change')).toHaveLength(2);

      // The first change event was for the initial input, but the second is
      // for the successful validation of the input.
      expect(wrapper.emitted('change')[1]).toEqual([
        {
          branch: search,
          source: defaultProps.suggestedSource,
          canSubmit: false,
        },
      ]);
    });

    it('renders an invalid state', () => {
      expect(branchValidation()).toEqual({
        text: i18n.branchNotAvailable,
        state: false,
      });
    });

    it('disables the submit button', () => {
      expect(findSubmitButton().attributes('disabled')).toBe('disabled');
    });
  });

  describe('given the branch request fails', () => {
    beforeEach(() => {
      mockRefEndpoint({ fail: true });

      createComponent();
      findBranchInput().setValue('foo');

      return waitForDebouncedRequests();
    });

    it('emits an error message', () => {
      expect(wrapper.emitted('error')).toEqual([['Failed to get ref.']]);
    });
  });

  // Begin source
  describe('changing the source input', () => {
    const search = 'foobar';

    beforeEach(() => {
      mockRefEndpoint({ search, delay: 1 });

      createComponent();
      findSourceInput().setValue(search);
    });

    it('emits a change event', () => {
      expect(wrapper.emitted('change')).toEqual([
        [
          {
            branch: defaultProps.suggestedBranch,
            source: search,
            canSubmit: false,
          },
        ],
      ]);
    });

    it('renders a loading state', () => {
      expect(sourceValidation()).toEqual({
        text: i18n.checkingSource,
        state: null,
      });
    });
  });

  describe('clearing the source input', () => {
    beforeEach(() => {
      mockRefEndpoint({ delay: 1 });

      createComponent();
      findSourceInput().setValue('');
    });

    it('does not send a request', () => {
      expect(mockAxios.history.get).toEqual([]);
    });

    it('emits a change event with the suggested source', () => {
      expect(wrapper.emitted('change')).toEqual([
        [
          {
            branch: defaultProps.suggestedBranch,
            source: defaultProps.suggestedSource,
            canSubmit: true,
          },
        ],
      ]);
    });
  });

  describe('given a source that exists', () => {
    const search = 'foobar';

    beforeEach(() => {
      mockRefEndpoint({ search });

      createComponent();
      findSourceInput().setValue(search);

      return waitForDebouncedRequests();
    });

    it('emits a change event', async () => {
      expect(wrapper.emitted('change')).toHaveLength(2);

      // The first change event was for the initial input, but the second is
      // for the successful validation of the input.
      expect(wrapper.emitted('change')[1]).toEqual([
        {
          branch: defaultProps.suggestedBranch,
          source: search,
          canSubmit: true,
        },
      ]);
    });

    it('renders a valid state', () => {
      expect(sourceValidation()).toEqual({
        text: i18n.sourceAvailable,
        state: true,
      });
    });

    it('does not disable the submit button', () => {
      expect(findSubmitButton().attributes('disabled')).toBe(undefined);
    });
  });

  describe('given the source does not exist', () => {
    const search = 'i-do-no-exist';

    beforeEach(() => {
      mockRefEndpoint({ search, expectMatches: false });

      createComponent();
      findSourceInput().setValue(search);

      return waitForDebouncedRequests();
    });

    it('emits a change event', async () => {
      expect(wrapper.emitted('change')).toHaveLength(2);

      // The first change event was for the initial input, but the second is
      // for the successful validation of the input.
      expect(wrapper.emitted('change')[1]).toEqual([
        {
          branch: defaultProps.suggestedBranch,
          source: search,
          canSubmit: false,
        },
      ]);
    });

    it('renders an invalid state', () => {
      expect(sourceValidation()).toEqual({
        text: i18n.sourceNotAvailable,
        state: false,
      });
    });

    it('disables the submit button', () => {
      expect(findSubmitButton().attributes('disabled')).toBe('disabled');
    });
  });

  describe('given the source request fails', () => {
    beforeEach(() => {
      mockRefEndpoint({ fail: true });

      createComponent();
      findSourceInput().setValue('foo');

      return waitForDebouncedRequests();
    });

    it('emits an error message', () => {
      expect(wrapper.emitted('error')).toEqual([['Failed to get ref.']]);
    });
  });
});
