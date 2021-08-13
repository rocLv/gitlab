import { fetchSubscriptions as fetchSubscriptionsREST } from '~/jira_connect/subscriptions/api';
import { SET_SUBSCRIPTIONS, SET_SUBSCRIPTIONS_LOADING } from './mutation_types';

export const fetchSubscriptions = async ({ commit }, subscriptionsPath) => {
  commit(SET_SUBSCRIPTIONS_LOADING, true);

  const data = await fetchSubscriptionsREST(subscriptionsPath);

  commit(SET_SUBSCRIPTIONS_LOADING, false);
  commit(SET_SUBSCRIPTIONS, data.data.subscriptions);
};
