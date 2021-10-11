<script>
import { GlIcon, GlCollapse, GlButton, GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import MaskedValue from '~/runner/components/helpers/masked_value.vue';
import RunnerRegistrationTokenReset from '~/runner/components/runner_registration_token_reset.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import RunnerInstructions from '~/vue_shared/components/runner_instructions/runner_instructions.vue';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '../constants';

export default {
  components: {
    GlIcon,
    GlCollapse,
    GlButton,
    GlLink,
    GlSprintf,
    ClipboardButton,
    MaskedValue,
    RunnerInstructions,
    RunnerRegistrationTokenReset,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    runnerInstallHelpPage: {
      default: null,
    },
  },
  props: {
    registrationToken: {
      type: String,
      required: true,
    },
    type: {
      type: String,
      required: true,
      validator(type) {
        return [INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE].includes(type);
      },
    },
  },
  data() {
    return {
      visible: false,
      currentRegistrationToken: this.registrationToken,
    };
  },
  computed: {
    rootUrl() {
      return gon.gitlab_url || '';
    },
    typeName() {
      switch (this.type) {
        case INSTANCE_TYPE:
          return s__('Runners|shared');
        case GROUP_TYPE:
          return s__('Runners|group');
        case PROJECT_TYPE:
          return s__('Runners|specific');
        default:
          return '';
      }
    },
    buttonText() {
      switch (this.type) {
        case INSTANCE_TYPE:
          return s__('Runners|Register an instance runner');
        case GROUP_TYPE:
          return s__('Runners|Register a group runner');
        case PROJECT_TYPE:
          return s__('Runners|Register a project runner');
        default:
          return s__('Runners|Register a runner');
      }
    },
  },
  methods: {
    onToggle() {
      this.visible = !this.visible;
    },
    onTokenReset(token) {
      this.currentRegistrationToken = token;
    },
  },
};
</script>

<template>
  <div class="gl-py-3 gl-border-1 gl-border-b-solid gl-border-gray-100">
    <div class="gl-display-flex">
      <gl-button class="gl-ml-auto" variant="confirm" @click="onToggle">
        {{ buttonText }}
        <gl-icon name="chevron-down" />
      </gl-button>
    </div>

    <gl-collapse :visible="visible">
      <div class="bs-callout">
        <h5 data-testid="runner-help-title">
          <gl-sprintf :message="__('Set up a %{type} runner manually')">
            <template #type>
              {{ typeName }}
            </template>
          </gl-sprintf>
        </h5>

        <ol>
          <li>
            <gl-link :href="runnerInstallHelpPage" data-testid="runner-help-link" target="_blank">
              {{ __("Install GitLab Runner and ensure it's running.") }}
            </gl-link>
          </li>
          <li>
            {{ __('Register the runner with this URL:') }}
            <br />

            <code data-testid="coordinator-url">{{ rootUrl }}</code>
            <clipboard-button :title="__('Copy URL')" :text="rootUrl" />
          </li>
          <li>
            {{ __('And this registration token:') }}
            <br />

            <code data-testid="registration-token"
              ><masked-value :value="currentRegistrationToken"
            /></code>
            <clipboard-button :title="__('Copy token')" :text="currentRegistrationToken" />
          </li>
        </ol>

        <runner-registration-token-reset :type="type" @tokenReset="onTokenReset" />

        <runner-instructions />
      </div>
    </gl-collapse>
  </div>
</template>
