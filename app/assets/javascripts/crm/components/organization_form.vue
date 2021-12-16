<script>
import { GlAlert, GlButton, GlDrawer, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { produce } from 'immer';
import { __, s__ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_GROUP } from '~/graphql_shared/constants';
import createOrganizationMutation from './queries/create_organization.mutation.graphql';
import updateOrganizationMutation from './queries/update_organization.mutation.graphql';
import getGroupOrganizationsQuery from './queries/get_group_organizations.query.graphql';

export default {
  components: {
    GlAlert,
    GlButton,
    GlDrawer,
    GlFormGroup,
    GlFormInput,
  },
  inject: ['groupFullPath', 'groupId'],
  props: {
    drawerOpen: {
      type: Boolean,
      required: true,
    },
    organization: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  data() {
    return {
      name: '',
      defaultRate: null,
      description: '',
      submitting: false,
      errorMessages: [],
    };
  },
  computed: {
    isInvalid() {
      return this.name.trim() === '';
    },
    isEditMode() {
      return Boolean(this.organization);
    },
    title() {
      return this.isEditMode ? this.$options.i18n.editTitle : this.$options.i18n.newTitle;
    },
    buttonLabel() {
      return this.isEditMode
        ? this.$options.i18n.editButtonLabel
        : this.$options.i18n.newButtonLabel;
    },
    mutation() {
      return this.isEditMode ? updateOrganizationMutation : createOrganizationMutation;
    },
    variables() {
      const { organization, name, defaultRate, description, isEditMode, groupId } = this;

      const variables = {
        input: {
          name,
          defaultRate: defaultRate ? parseFloat(defaultRate) : null,
          description,
        },
      };

      if (isEditMode) {
        variables.input.id = organization.id;
      } else {
        variables.input.groupId = convertToGraphQLId(TYPE_GROUP, groupId);
      }

      return variables;
    },
  },
  mounted() {
    if (this.isEditMode) {
      const { organization } = this;

      this.name = organization.name || '';
      this.defaultRate = organization.defaultRate || '';
      this.description = organization.description || '';
    }
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
          if (
            data.customerRelationsOrganizationCreate?.errors.length === 0 ||
            data.customerRelationsOrganizationUpdate?.errors.length === 0
          ) {
            close(true);
          }

          this.submitting = false;
        })
        .catch(() => {
          this.errorMessages = [this.$options.i18n.somethingWentWrong];
          this.submitting = false;
        });
    },
    close(success) {
      this.$emit('close', success);
    },
    updateCache(store, { data }) {
      const mutationData =
        data.customerRelationsOrganizationCreate || data.customerRelationsOrganizationUpdate;

      if (mutationData?.errors.length > 0) {
        this.errorMessages = mutationData.errors;
        return;
      }

      if (this.isEditMode) return;

      const queryArgs = {
        query: getGroupOrganizationsQuery,
        variables: { groupFullPath: this.groupFullPath },
      };

      const sourceData = store.readQuery(queryArgs);

      queryArgs.data = produce(sourceData, (draftState) => {
        draftState.group.organizations.nodes = [
          ...sourceData.group.organizations.nodes,
          mutationData.organization,
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
  },
  i18n: {
    newButtonLabel: s__('Crm|Create organization'),
    editButtonLabel: __('Save changes'),
    cancel: __('Cancel'),
    name: __('Name'),
    defaultRate: s__('Crm|Default rate (optional)'),
    description: __('Description (optional)'),
    newTitle: s__('Crm|New organization'),
    editTitle: s__('Crm|Edit organization'),
    somethingWentWrong: __('Something went wrong. Please try again.'),
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
      <h4>{{ title }}</h4>
    </template>
    <gl-alert v-if="errorMessages.length" variant="danger" @dismiss="errorMessages = []">
      <ul class="gl-mb-0! gl-ml-5">
        <li v-for="error in errorMessages" :key="error">
          {{ error }}
        </li>
      </ul>
    </gl-alert>
    <form @submit.prevent="save">
      <gl-form-group :label="$options.i18n.name" label-for="organization-name">
        <gl-form-input id="organization-name" v-model="name" />
      </gl-form-group>
      <gl-form-group :label="$options.i18n.defaultRate" label-for="organization-default-rate">
        <gl-form-input
          id="organization-default-rate"
          v-model="defaultRate"
          type="number"
          step="0.01"
        />
      </gl-form-group>
      <gl-form-group :label="$options.i18n.description" label-for="organization-description">
        <gl-form-input id="organization-description" v-model="description" />
      </gl-form-group>
      <span class="gl-float-right">
        <gl-button data-testid="cancel-button" @click="close(false)">
          {{ $options.i18n.cancel }}
        </gl-button>
        <gl-button
          variant="confirm"
          :disabled="isInvalid"
          :loading="submitting"
          data-testid="save-organization-button"
          type="submit"
          >{{ buttonLabel }}</gl-button
        >
      </span>
    </form>
  </gl-drawer>
</template>
