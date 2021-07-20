import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import BaseComponent from '~/cycle_analytics/components/base.vue';
import PathNavigation from '~/cycle_analytics/components/path_navigation.vue';
import StageTable from '~/cycle_analytics/components/stage_table.vue';
import ValueStreamFilters from '~/cycle_analytics/components/value_stream_filters.vue';
import { NOT_ENOUGH_DATA_ERROR } from '~/cycle_analytics/constants';
import initState from '~/cycle_analytics/store/state';
import {
  permissions,
  transformedProjectStagePathData,
  selectedStage,
  issueEvents,
  createdBefore,
  createdAfter,
  currentGroup,
} from './mock_data';

const selectedStageEvents = issueEvents.events;
const noDataSvgPath = 'path/to/no/data';
const noAccessSvgPath = 'path/to/no/access';

Vue.use(Vuex);

let wrapper;

const defaultState = {
  permissions,
  selectedStageEvents,
  selectedStage,
  currentGroup,
  createdBefore,
  createdAfter,
};

function createStore({ initialState = {}, initialGetters = {} }) {
  return new Vuex.Store({
    state: {
      ...initState(),
      ...defaultState,
      ...initialState,
    },
    getters: {
      pathNavigationData: () => transformedProjectStagePathData,
      ...initialGetters,
    },
  });
}

function createComponent({ initialState, initialGetters } = {}) {
  return extendedWrapper(
    shallowMount(BaseComponent, {
      store: createStore({ initialState, initialGetters }),
      propsData: {
        noDataSvgPath,
        noAccessSvgPath,
      },
      stubs: {
        StageTable,
      },
    }),
  );
}

const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
const findPathNavigation = () => wrapper.findComponent(PathNavigation);
const findOverviewMetrics = () => wrapper.findByTestId('vsa-stage-overview-metrics');
const findStageTable = () => wrapper.findComponent(StageTable);
const findStageEvents = () => findStageTable().props('stageEvents');
const findEmptyStageTitle = () => wrapper.findComponent(GlEmptyState).props('title');
const findFilters = () => wrapper.findComponent(ValueStreamFilters);

describe('Value stream analytics component', () => {
  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders the path navigation component', () => {
    expect(findPathNavigation().exists()).toBe(true);
  });

  it('renders the overview metrics', () => {
    expect(findOverviewMetrics().exists()).toBe(true);
  });

  it('renders the stage table', () => {
    expect(findStageTable().exists()).toBe(true);
  });

  it('renders the stage table events', () => {
    expect(findStageEvents()).toEqual(selectedStageEvents);
  });

  it('does not render the loading icon', () => {
    expect(findLoadingIcon().exists()).toBe(false);
  });

  describe('isLoading = true', () => {
    beforeEach(() => {
      wrapper = createComponent({
        initialState: { isLoading: true },
      });
    });

    it('renders the path navigation component with prop `loading` set to true', () => {
      expect(findPathNavigation().props('loading')).toBe(true);
    });

    it('does not render the overview metrics', () => {
      expect(findOverviewMetrics().exists()).toBe(false);
    });

    it('does not render the stage table', () => {
      expect(findStageTable().exists()).toBe(false);
    });

    it('renders the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('isLoadingStage = true', () => {
    beforeEach(() => {
      wrapper = createComponent({
        initialState: { isLoadingStage: true },
      });
    });

    it('renders the stage table with a loading icon', () => {
      const tableWrapper = findStageTable();
      expect(tableWrapper.exists()).toBe(true);
      expect(tableWrapper.find(GlLoadingIcon).exists()).toBe(true);
    });

    it('renders the path navigation loading state', () => {
      expect(findPathNavigation().exists()).toBe(true);
    });
  });

  describe('isEmptyStage = true', () => {
    const emptyStageParams = {
      isEmptyStage: true,
      selectedStage: { ...selectedStage, emptyStageText: 'This stage is empty' },
    };
    beforeEach(() => {
      wrapper = createComponent({ initialState: emptyStageParams });
    });

    it('renders the empty stage with `Not enough data` message', () => {
      expect(findEmptyStageTitle()).toBe(NOT_ENOUGH_DATA_ERROR);
    });

    describe('with a selectedStageError', () => {
      beforeEach(() => {
        wrapper = createComponent({
          initialState: {
            ...emptyStageParams,
            selectedStageError: 'There is too much data to calculate',
          },
        });
      });

      it('renders the empty stage with `There is too much data to calculate` message', () => {
        expect(findEmptyStageTitle()).toBe('There is too much data to calculate');
      });
    });
  });

  describe('without enough permissions', () => {
    beforeEach(() => {
      wrapper = createComponent({
        initialState: {
          permissions: {
            ...permissions,
            [selectedStage.id]: false,
          },
        },
      });
    });

    it('renders the empty stage with `You need permission.` message', () => {
      expect(findEmptyStageTitle()).toBe('You need permission.');
    });
  });

  describe('without a selected stage', () => {
    beforeEach(() => {
      wrapper = createComponent({
        initialGetters: { pathNavigationData: () => [] },
        initialState: { selectedStage: null, isEmptyStage: true },
      });
    });

    it('renders the stage table', () => {
      expect(findStageTable().exists()).toBe(true);
    });

    it('renders the filters', () => {
      expect(findFilters().exists()).toBe(true);
    });

    it('does not render the path navigation', () => {
      expect(findPathNavigation().exists()).toBe(false);
    });

    it('does not render the stage table events', () => {
      expect(findStageEvents()).toHaveLength(0);
    });

    it('does not render the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });
});
