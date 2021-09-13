<script>
import { GlDropdownForm, GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

const BRANCH = 'branch';
const SOURCE = 'source';

export const i18n = {
  branch: __('Branch name'),
  source: __('Source (branch or tag)'),
  branchAvailable: __('Branch name is available'),
  sourceAvailable: __('Source is available'),
  checkingBranch: __('Checking branch name availability…'),
  checkingSource: __('Checking source availability…'),
  branchNotAvailable: __('Branch is already taken'),
  sourceNotAvailable: __('Source is not available'),
};

export default {
  components: {
    GlDropdownForm,
    GlButton,
    GlFormGroup,
    GlFormInput,
  },
  props: {
    buttonText: {
      type: String,
      required: true,
    },
    suggestedBranch: {
      type: String,
      required: true,
    },
    suggestedSource: {
      type: String,
      required: true,
    },
    refsPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      [BRANCH]: {
        value: this.suggestedBranch,
        suggested: this.suggestedBranch,
        loading: false,
        state: null,
        inputId: uniqueId('create-merge-request-branch-name'),
      },
      [SOURCE]: {
        value: this.suggestedSource,
        suggested: this.suggestedSource,
        loading: false,
        state: null,
        inputId: uniqueId('create-merge-request-source'),
      },
    };
  },
  computed: {
    loading() {
      return this.branch.loading || this.source.loading;
    },
    valid() {
      return this.branch.state !== false && this.source.state !== false;
    },
    canSubmit() {
      return !this.loading && this.valid;
    },
    branchDescription() {
      return this.branch.loading ? i18n.checkingBranch : null;
    },
    sourceDescription() {
      return this.source.loading ? i18n.checkingSource : null;
    },
  },
  methods: {
    onChange(values) {
      this.$emit('change', {
        branch: this.branch.value,
        source: this.source.value,
        canSubmit: this.canSubmit,
        ...values,
      });
    },
    onUpdate(ref, branchOrSource) {
      // If the user clears the input, use the suggested value
      if (!ref) {
        this[branchOrSource].loading = false;
        this[branchOrSource].state = true;
        this.onChange({ [branchOrSource]: this[branchOrSource].suggested });
        return;
      }

      this[branchOrSource].loading = true;
      this[branchOrSource].state = null;

      this.onChange({ [branchOrSource]: ref });
    },
    async checkRef(ref, branchOrSource) {
      if (!ref) return;

      try {
        const refExists = await this.refExists(ref, branchOrSource);
        this[branchOrSource].loading = false;

        // To be valid, the source must already exist, but the branch must not.
        this[branchOrSource].state = branchOrSource === BRANCH ? !refExists : refExists;
        this.onChange({ [branchOrSource]: ref });
      } catch {
        this[branchOrSource].loading = false;
        this[branchOrSource].state = null;
      }
    },
    async refExists(ref, branchOrSource) {
      if (!ref) return false;

      try {
        const { data } = await axios.get(`${this.refsPath}${encodeURIComponent(ref)}`);

        // The original code uses key order rather than key name... why?
        const [branchesKey, tagsKey] = Object.keys(data);
        const branches = data[branchesKey] ?? [];
        const tags = data[tagsKey] ?? [];

        const refs = branchOrSource === BRANCH ? branches : [...branches, ...tags];
        return refs.includes(ref);
      } catch (error) {
        this.$emit('error', __('Failed to get ref.'));
        throw error;
      }
    },
  },
  BRANCH,
  SOURCE,
  debounceDelay: 500,
  i18n,
};
</script>

<template>
  <gl-dropdown-form @submit="$emit('submit')">
    <gl-form-group
      :label="$options.i18n.branch"
      :label-for="branch.inputId"
      :valid-feedback="$options.i18n.branchAvailable"
      :invalid-feedback="$options.i18n.branchNotAvailable"
      :description="branchDescription"
      :state="branch.state"
    >
      <gl-form-input
        :id="branch.inputId"
        :value="branch.value"
        name="branch"
        :placeholder="suggestedBranch"
        :debounce="$options.debounceDelay"
        @update="onUpdate($event, $options.BRANCH)"
        @input="checkRef($event, $options.BRANCH)"
      />
    </gl-form-group>

    <gl-form-group
      :label="$options.i18n.source"
      :label-for="source.inputId"
      :valid-feedback="$options.i18n.sourceAvailable"
      :invalid-feedback="$options.i18n.sourceNotAvailable"
      :description="sourceDescription"
      :state="source.state"
    >
      <gl-form-input
        :id="source.inputId"
        :value="source.value"
        name="source"
        :placeholder="suggestedSource"
        :debounce="$options.debounceDelay"
        @update="onUpdate($event, $options.SOURCE)"
        @input="checkRef($event, $options.SOURCE)"
      />
    </gl-form-group>

    <gl-button variant="confirm" type="submit" :disabled="!canSubmit" class="disable-hover">{{
      buttonText
    }}</gl-button>
  </gl-dropdown-form>
</template>
