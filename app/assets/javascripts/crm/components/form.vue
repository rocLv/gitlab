<script>
import { GlAlert, GlButton, GlDrawer, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { get as getPropValueByPath, isEmpty } from 'lodash';
import { produce } from 'immer';
import { __ } from '~/locale';
import { INDEX_ROUTE_NAME } from '../constants';

export default {
  components: {
    GlAlert,
    GlButton,
    GlDrawer,
    GlFormGroup,
    GlFormInput,
  },
  props: {
    drawerOpen: {
      type: Boolean,
      required: true,
    },
    getQuery: {
      type: Object,
      required: false,
      default: null,
    },
    getQueryVariables: {
      type: Object,
      required: false,
      default: null,
    },
    getQueryNodePath: {
      type: String,
      required: false,
      default: null,
    },
    createMutation: {
      type: Object,
      required: false,
      default: () => {},
    },
    updateMutation: {
      type: Object,
      required: false,
      default: () => {},
    },
    existingModel: {
      type: Object,
      required: false,
      default: () => {},
    },
    additionalCreateParams: {
      type: Object,
      required: false,
      default: () => {},
    },
    fields: {
      type: Array,
      required: true,
    },
    i18n: {
      type: Object,
      required: true,
    },
    isEditMode: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      model: {},
      submitting: false,
      errorMessages: [],
    };
  },
  computed: {
    isInvalid() {
      const { fields, model } = this;

      return fields.some((field) => {
        return field.required && isEmpty(model[field.name]);
      });
    },
    title() {
      const { editPrefix, newPrefix } = this.$options.i18n;

      const prefix = this.isEditMode ? editPrefix : newPrefix;

      return `${prefix} ${this.i18n.modelName}`;
    },
    buttonLabel() {
      const { create, saveChanges } = this.$options.i18n;

      return this.isEditMode ? saveChanges : create;
    },
    mutation() {
      return this.isEditMode ? this.updateMutation : this.createMutation;
    },
    variables() {
      const { additionalCreateParams, fields, isEditMode, model } = this;

      const variables = fields.reduce((map, field) => {
        const result = { ...map };
        if (model[field.name] != null && field.input?.type === 'number') {
          result[field.name] = parseFloat(model[field.name]);
        } else {
          result[field.name] = model[field.name];
        }
        return result;
      }, {});

      if (isEditMode) {
        return { input: { id: this.existingModel.id, ...variables } };
      }

      return { input: { ...additionalCreateParams, ...variables } };
    },
  },
  mounted() {
    this.model = { ...this.existingModel };
  },
  methods: {
    save() {
      const { mutation, variables, updateCache, close } = this;

      this.submitting = true;

      return this.$apollo
        .mutate({
          mutation,
          variables,
          update: updateCache,
        })
        .then(({ data }) => {
          if (data[Object.keys(data)[0]].errors.length === 0) {
            close(true);
          }
        })
        .catch(() => {
          this.errorMessages = [this.$options.i18n.somethingWentWrong];
        })
        .finally(() => {
          this.submitting = false;
        });
    },
    close(success) {
      let message;
      if (success) {
        const { i18n, isEditMode } = this;
        const { added, updated } = this.$options.i18n;
        message = `${i18n.modelName} `;
        message += isEditMode ? updated : added;
      }

      // This is needed so toast perists when route is changed
      this.$root.$toast.show(message);
      this.$router.replace({ name: INDEX_ROUTE_NAME });
    },
    updateCache(store, { data }) {
      const mutationData = data[Object.keys(data)[0]];

      if (mutationData?.errors.length > 0) {
        this.errorMessages = mutationData.errors;
        return;
      }

      const { getQuery, getQueryVariables, isEditMode } = this;
      if (isEditMode) return;
      if (!getQuery) return;

      const queryArgs = {
        query: getQuery,
        variables: { ...getQueryVariables },
      };

      const sourceData = store.readQuery(queryArgs);

      queryArgs.data = produce(sourceData, (draftState) => {
        getPropValueByPath(draftState, this.getQueryNodePath).nodes = [
          ...getPropValueByPath(draftState, this.getQueryNodePath).nodes,
          mutationData[Object.keys(mutationData)[0]],
        ];
      });

      store.writeQuery(queryArgs);
    },
    getDrawerHeaderHeight() {
      const wrapperEl = document.querySelector('.content-wrapper');

      if (wrapperEl) {
        return `${wrapperEl.offsetTop}px`;
      }

      return '';
    },
    getFieldLabel(field) {
      const optionalSuffix = field.required ? '' : ` ${this.$options.i18n.optional}`;
      return field.label + optionalSuffix;
    },
  },
  i18n: {
    create: __('Create'),
    saveChanges: __('Save changes'),
    cancel: __('Cancel'),
    optional: __('(optional)'),
    newPrefix: __('New'),
    editPrefix: __('Edit'),
    somethingWentWrong: __('Something went wrong. Please try again.'),
    added: __('has been added'),
    updated: __('has been updated'),
  },
};
</script>

<template>
  <gl-drawer
    class="gl-drawer-responsive"
    :open="drawerOpen"
    :header-height="getDrawerHeaderHeight()"
    @close="close(false)"
  >
    <template #title>
      <h3>{{ title }}</h3>
    </template>
    <gl-alert v-if="errorMessages.length" variant="danger" @dismiss="errorMessages = []">
      <ul class="gl-mb-0! gl-ml-5">
        <li v-for="error in errorMessages" :key="error">
          {{ error }}
        </li>
      </ul>
    </gl-alert>
    <form @submit.prevent="save">
      <gl-form-group
        v-for="field in fields"
        :key="field.name"
        :label="getFieldLabel(field)"
        :label-for="field.name"
      >
        <gl-form-input :id="field.name" v-bind="field.input" v-model="model[field.name]" />
      </gl-form-group>
      <span class="gl-float-right">
        <gl-button data-testid="cancel-button" @click="close(false)">
          {{ $options.i18n.cancel }}
        </gl-button>
        <gl-button
          variant="confirm"
          :disabled="isInvalid"
          :loading="submitting"
          data-testid="save-button"
          type="submit"
          >{{ buttonLabel }}</gl-button
        >
      </span>
    </form>
  </gl-drawer>
</template>
