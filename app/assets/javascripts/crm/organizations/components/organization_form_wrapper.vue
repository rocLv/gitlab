<script>
import { s__, __ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_CRM_ORGANIZATION, TYPE_GROUP } from '~/graphql_shared/constants';
import { EDIT_ROUTE_NAME } from '../../constants';
import OrganizationForm from '../../components/form.vue';
import getGroupOrganizationsQuery from './queries/get_group_organizations.query.graphql';
import createOrganizationMutation from './queries/create_organization.mutation.graphql';
import updateOrganizationMutation from './queries/update_organization.mutation.graphql';

export default {
  components: {
    OrganizationForm,
  },
  inject: ['groupFullPath', 'groupId'],
  props: {
    isEditMode: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      contacts: [],
      error: false,
    };
  },
  computed: {
    isLoading() {
      return this.$root.$children[0].$apollo.queries.organizations.loading;
    },
    editingOrganization() {
      if (this.$route.name !== EDIT_ROUTE_NAME) return null;

      return this.$root.$children[0].organizations.find(
        ({ id }) => id === convertToGraphQLId(TYPE_CRM_ORGANIZATION, this.$route.params.id),
      );
    },
    groupGraphQLId() {
      return convertToGraphQLId(TYPE_GROUP, this.groupId);
    },
  },
  fields: [
    { name: 'name', label: __('Name'), required: true },
    {
      name: 'defaultRate',
      label: s__('Crm|Default rate'),
      input: { type: 'number', step: '0.01' },
    },
    { name: 'description', label: __('Description') },
  ],
  i18n: {
    modelName: s__('Crm|organization'),
  },
  getGroupOrganizationsQuery,
  createOrganizationMutation,
  updateOrganizationMutation,
};
</script>

<template>
  <organization-form
    v-if="!isLoading"
    :drawer-open="true"
    :get-query="$options.getGroupOrganizationsQuery"
    :get-query-variables="{ groupFullPath }"
    get-query-node-path="group.organizations"
    :create-mutation="$options.createOrganizationMutation"
    :additional-create-params="{ groupId: groupGraphQLId }"
    :update-mutation="$options.updateOrganizationMutation"
    :existing-model="editingOrganization"
    :fields="$options.fields"
    :i18n="$options.i18n"
    :is-edit-mode="isEditMode"
  />
</template>
