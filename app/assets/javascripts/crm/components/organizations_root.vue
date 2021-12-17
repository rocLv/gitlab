<script>
import { GlAlert, GlButton, GlLoadingIcon, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import { s__, __ } from '~/locale';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPE_CRM_ORGANIZATION } from '~/graphql_shared/constants';
import { INDEX_ROUTE_NAME, NEW_ROUTE_NAME, EDIT_ROUTE_NAME } from '../constants';
import getGroupOrganizationsQuery from './queries/get_group_organizations.query.graphql';
import OrganizationForm from './organization_form.vue';

export default {
  components: {
    GlAlert,
    GlButton,
    GlLoadingIcon,
    GlTable,
    OrganizationForm,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['canAdminCrmOrganization', 'groupFullPath', 'groupIssuesPath'],
  data() {
    return {
      error: false,
      organizations: [],
    };
  },
  apollo: {
    organizations: {
      query() {
        return getGroupOrganizationsQuery;
      },
      variables() {
        return {
          groupFullPath: this.groupFullPath,
        };
      },
      update(data) {
        return this.extractOrganizations(data);
      },
      error() {
        this.error = true;
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.organizations.loading;
    },
    showNewForm() {
      return this.$route.name === NEW_ROUTE_NAME;
    },
    showEditForm() {
      return !this.isLoading && this.$route.name === EDIT_ROUTE_NAME;
    },
    canAdmin() {
      return parseBoolean(this.canAdminCrmOrganization);
    },
    editingOrganization() {
      return this.organizations.find(
        ({ id }) => id === convertToGraphQLId(TYPE_CRM_ORGANIZATION, this.$route.params.id),
      );
    },
  },
  methods: {
    extractOrganizations(data) {
      const organizations = data?.group?.organizations?.nodes || [];
      return organizations.slice().sort((a, b) => a.name.localeCompare(b.name));
    },
    getIssuesPath(path, value) {
      return `${path}?scope=all&state=opened&crm_organization_id=${value}`;
    },
    displayNewForm() {
      if (this.showNewForm) return;

      this.$router.push({ name: NEW_ROUTE_NAME });
    },
    hideNewForm(success) {
      if (success) this.$toast.show(this.$options.i18n.organizationAdded);

      this.$router.replace({ name: INDEX_ROUTE_NAME });
    },
    hideEditForm(success) {
      if (success) this.$toast.show(this.$options.i18n.organizationUpdated);

      this.editingOrganizationId = 0;
      this.$router.replace({ name: INDEX_ROUTE_NAME });
    },
    edit(id) {
      if (this.showEditForm) return;

      this.editingOrganizationId = id;
      this.$router.push({ name: EDIT_ROUTE_NAME, params: { id } });
    },
  },
  fields: [
    { key: 'name', sortable: true },
    { key: 'defaultRate', sortable: true },
    { key: 'description', sortable: true },
    {
      key: 'id',
      label: '',
      formatter: (id) => {
        return getIdFromGraphQLId(id);
      },
    },
  ],
  i18n: {
    emptyText: s__('Crm|No organizations found'),
    issuesButtonLabel: __('View issues'),
    editButtonLabel: __('Edit'),
    title: __('Customer relations organizations'),
    newOrganization: s__('Crm|New organization'),
    errorText: __('Something went wrong. Please try again.'),
    organizationAdded: s__('Crm|Organization has been added'),
    organizationUpdated: s__('Crm|Organization has been updated'),
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="error" variant="danger" class="gl-mt-6" @dismiss="error = false">
      {{ $options.i18n.errorText }}
    </gl-alert>
    <div
      class="gl-display-flex gl-align-items-baseline gl-flex-direction-row gl-justify-content-space-between gl-mt-6"
    >
      <h2 class="gl-font-size-h2 gl-my-0">
        {{ $options.i18n.title }}
      </h2>
      <div
        v-if="canAdmin"
        class="gl-display-none gl-md-display-flex gl-align-items-center gl-justify-content-end"
      >
        <gl-button variant="confirm" data-testid="new-organization-button" @click="displayNewForm">
          {{ $options.i18n.newOrganization }}
        </gl-button>
      </div>
    </div>
    <organization-form v-if="showNewForm" :drawer-open="showNewForm" @close="hideNewForm" />
    <organization-form
      v-if="showEditForm"
      :is-edit-mode="true"
      :organization="editingOrganization"
      :drawer-open="showEditForm"
      @close="hideEditForm"
    />
    <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="lg" />
    <gl-table
      v-else
      class="gl-mt-5"
      :items="organizations"
      :fields="$options.fields"
      :empty-text="$options.i18n.emptyText"
      show-empty
    >
      <template #cell(id)="data">
        <gl-button
          v-gl-tooltip.hover.bottom="$options.i18n.issuesButtonLabel"
          class="gl-mr-3"
          data-testid="issues-link"
          icon="issues"
          :aria-label="$options.i18n.issuesButtonLabel"
          :href="getIssuesPath(groupIssuesPath, data.value)"
        />
        <gl-button
          v-if="canAdmin"
          v-gl-tooltip.hover.bottom="$options.i18n.editButtonLabel"
          data-testid="edit-organization-button"
          icon="pencil"
          :aria-label="$options.i18n.editButtonLabel"
          @click="edit(data.value)"
        />
      </template>
    </gl-table>
  </div>
</template>
