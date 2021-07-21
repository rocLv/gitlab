import createStateCE from '~/boards/stores/state';

export default () => ({
  ...createStateCE(),

  canAdminEpic: false,
  isShowingEpicsSwimlanes: false,
  epicsSwimlanesFetchInProgress: {
    epicLanesFetchInProgress: false,
    listItemsFetchInProgress: false,
    epicLanesFetchMoreInProgress: false,
  },
  hasMoreEpics: false,
  epicsEndCursor: null,
  epics: [],
  epicsFlags: {},
  milestones: [],
  milestonesLoading: false,
  iterations: [],
  iterationsLoading: false,
  assignees: [],
  assigneesLoading: false,
});
