import { createLocalVue, mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RunnerHeader from '~/runner/components/runner_header.vue';
import getRunnerQuery from '~/runner/graphql/get_runner.query.graphql';
import AdminRunnerEditApp from '~//runner/admin_runner_edit/admin_runner_edit_app.vue';
import { captureException } from '~/runner/sentry_utils';

import { runnerData } from '../mock_data';

jest.mock('~/flash');
jest.mock('~/runner/sentry_utils');

const mockRunnerGraphqlId = runnerData.data.runner.id;
const mockRunnerId = `${getIdFromGraphQLId(mockRunnerGraphqlId)}`;

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('AdminRunnerEditApp', () => {
  let wrapper;
  let mockRunnerQuery;

  const findRunnerHeader = () => wrapper.findComponent(RunnerHeader);

  const createComponentWithApollo = ({ props = {}, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(AdminRunnerEditApp, {
      localVue,
      apolloProvider: createMockApollo([[getRunnerQuery, mockRunnerQuery]]),
      propsData: {
        runnerId: mockRunnerId,
        ...props,
      },
    });

    return waitForPromises();
  };

  beforeEach(() => {
    mockRunnerQuery = jest.fn().mockResolvedValue(runnerData);
  });

  afterEach(() => {
    mockRunnerQuery.mockReset();
    wrapper.destroy();
  });

  it('expect GraphQL ID to be requested', async () => {
    await createComponentWithApollo();

    expect(mockRunnerQuery).toHaveBeenCalledWith({ id: mockRunnerGraphqlId });
  });

  it('displays the runner id', async () => {
    await createComponentWithApollo({ mountFn: mount });

    expect(findRunnerHeader().text()).toContain(`Runner #${mockRunnerId} created`);
  });

  it('displays the runner type and status', async () => {
    await createComponentWithApollo({ mountFn: mount });

    expect(findRunnerHeader().text()).toContain(`never contacted`);
    expect(findRunnerHeader().text()).toContain(`shared`);
  });

  describe('When there is an error', () => {
    beforeEach(async () => {
      mockRunnerQuery = jest.fn().mockRejectedValueOnce(new Error('Error!'));
      await createComponentWithApollo();
    });

    it('error is reported to sentry', () => {
      expect(captureException).toHaveBeenCalledWith({
        error: new Error('Network error: Error!'),
        component: 'AdminRunnerEditApp',
      });
    });

    it('error is shown to the user', () => {
      expect(createAlert).toHaveBeenCalled();
    });
  });
});
