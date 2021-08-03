<script>
import { GlToggle, GlSafeHtmlDirective } from '@gitlab/ui';
import { DISABLED_AND_UNOVERRIDABLE, DISABLED_WITH_OVERRIDE, ENABLED } from '../constants';

export default {
  components: {
    GlToggle,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  props: {
    groupFullPath: {
      type: String,
      required: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    value: {
      type: String,
      required: false,
      default: DISABLED_AND_UNOVERRIDABLE,
    },
    instanceRunnersText: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      saving: false,
      enabled: this.value === ENABLED,
      overridable: this.value === DISABLED_WITH_OVERRIDE,
    };
  },
  watch: {
    enabled(isEnabled) {
      if (isEnabled) {
        // Overridable is automatically disabled if this is enabled
        this.overridable = false;
        this.saveSetting(ENABLED);
      } else if (this.overridable) {
        this.saveSetting(DISABLED_WITH_OVERRIDE);
      } else {
        this.saveSetting(DISABLED_AND_UNOVERRIDABLE);
      }
    },
    overridable(isOverridable) {
      if (isOverridable) {
        this.saveSetting(DISABLED_WITH_OVERRIDE);
      } else {
        this.saveSetting(DISABLED_AND_UNOVERRIDABLE);
      }
    },
  },
  methods: {
    async saveSetting(setting) {
      this.saving = true;
      try {
        // TODO settings mutation https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67256
        // with variables:
        // const variables = {
        //   fullPath: this.groupFullPath,
        //   sharedRunnersSetting: setting,
        // };
        await new Promise((resolve) => setTimeout(resolve, 1500));

        this.$emit('input', setting);
      } finally {
        this.saving = false;
      }
    },
  },
};
</script>

<template>
  <div class="bs-callout">
    <p>
      {{ __('These runners are shared across this GitLab instance.') }}
    </p>
    <p v-safe-html="instanceRunnersText"></p>
    <gl-toggle
      v-model="enabled"
      :is-loading="loading || saving"
      :disabled="false"
      :label="__('Enable shared runners for this group')"
      :help="__('Enable shared runners for all projects and subgroups in this group.')"
    />
    <gl-toggle
      v-model="overridable"
      :is-loading="loading || saving"
      class="gl-mt-5"
      :disabled="enabled"
      :label="__('Allow projects and subgroups to override the group setting')"
      :help="__('Allows projects or subgroups in this group to override the global setting.')"
    />
  </div>
</template>
