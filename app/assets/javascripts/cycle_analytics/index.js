import Vue from 'vue';
import Translate from '../vue_shared/translate';
import CycleAnalytics from './components/base.vue';
import createStore from './store';

Vue.use(Translate);

export default () => {
  const store = createStore();
  const el = document.querySelector('#js-cycle-analytics');
  const {
    noAccessSvgPath,
    noDataSvgPath,
    requestPath,
    fullPath,
    parentPath,
    groupPath,
    groupId,
    labelsPath,
    milestonesPath,
  } = el.dataset;

  store.dispatch('initializeVsa', {
    currentGroup: { id: parseInt(groupId, 10), path: groupPath || parentPath },
    endpoints: {
      requestPath,
      labelsPath,
      milestonesPath,
      fullPath,
    },
  });

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'CycleAnalytics',
    store,
    render: (createElement) =>
      createElement(CycleAnalytics, {
        props: {
          noDataSvgPath,
          noAccessSvgPath,
          fullPath,
        },
      }),
  });
};
