<script>
import createFlash from '~/flash';
import { fetchPolicies } from '~/lib/graphql';
import RunnerList from '../components/runner_list.vue';
import RunnerManualSetupHelp from '../components/runner_manual_setup_help.vue';
import RunnerTypeHelp from '../components/runner_type_help.vue';
import { I18N_FETCH_ERROR, GROUP_TYPE } from '../constants';
import getGroupRunnersQuery from '../graphql/get_group_runners.query.graphql';
import { captureException } from '../sentry_utils';
import InstanceRunnersToggle from './instance_runners_toggle.vue';

export default {
  name: 'GroupRunnersApp',
  components: {
    InstanceRunnersToggle,
    RunnerList,
    RunnerManualSetupHelp,
    RunnerTypeHelp,
  },
  props: {
    registrationToken: {
      type: String,
      required: true,
    },
    groupFullPath: {
      type: String,
      required: true,
    },
    instanceRunnersText: {
      type: String,
      required: true,
    }
  },
  data() {
    return {
      group: {
        sharedRunnersSetting: null,
        runners: {
          items: [],
        },
      },
    };
  },
  apollo: {
    group: {
      query: getGroupRunnersQuery,
      // Runners can be updated by users directly in this list.
      // A "cache and network" policy prevents outdated filtered
      // results.
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      variables() {
        return this.variables;
      },
      update(data) {
        const { runners, sharedRunnersSetting } = data?.group;
        return {
          sharedRunnersSetting,
          runners: {
            items: runners?.nodes || [],
          },
        };
      },
      error(error) {
        createFlash({ message: I18N_FETCH_ERROR });

        this.reportToSentry(error);
      },
    },
  },
  computed: {
    variables() {
      return {
        groupFullPath: this.groupFullPath,
      };
    },
    groupLoading() {
      return this.$apollo.queries.group.loading;
    },
    noRunnersFound() {
      return !this.groupLoading && !this.group.runners.items.length;
    },
  },
  errorCaptured(error) {
    this.reportToSentry(error);
  },
  methods: {
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
  },
  GROUP_TYPE,
};
</script>

<template>
  <div>
    <div class="row">
      <div class="col-sm-6">
        <runner-type-help />
      </div>
      <div class="col-sm-6">
        <instance-runners-toggle
          v-model="group.sharedRunnersSetting"
          :instance-runners-text="instanceRunnersText"
          :loading="groupLoading"
          :group-full-path="groupFullPath"
        />
        <runner-manual-setup-help
          :registration-token="registrationToken"
          :type="$options.GROUP_TYPE"
        />
      </div>
    </div>

    <div v-if="noRunnersFound" class="gl-text-center gl-p-5">
      {{ __('No runners found') }}
    </div>
    <template v-else>
      <runner-list :runners="group.runners.items" :loading="groupLoading" />
    </template>
  </div>
</template>
