<script>
import { s__, __ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_CRM_CONTACT, TYPE_GROUP } from '~/graphql_shared/constants';
import { EDIT_ROUTE_NAME } from '../../constants';
import ContactForm from '../../components/form.vue';
import getGroupContactsQuery from './queries/get_group_contacts.query.graphql';
import createContactMutation from './queries/create_contact.mutation.graphql';
import updateContactMutation from './queries/update_contact.mutation.graphql';

export default {
  components: {
    ContactForm,
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
      return this.$root.$children[0].$apollo.queries.contacts.loading;
    },
    editingContact() {
      if (this.$route.name !== EDIT_ROUTE_NAME) return null;

      return this.$root.$children[0].contacts.find(
        ({ id }) => id === convertToGraphQLId(TYPE_CRM_CONTACT, this.$route.params.id),
      );
    },
    groupGraphQLId() {
      return convertToGraphQLId(TYPE_GROUP, this.groupId);
    },
  },
  fields: [
    { name: 'firstName', label: __('First name'), required: true },
    { name: 'lastName', label: __('Last name'), required: true },
    { name: 'email', label: __('Email'), required: true },
    { name: 'phone', label: __('Phone') },
    { name: 'description', label: __('Description') },
  ],
  i18n: {
    modelName: s__('Crm|contact'),
  },
  getGroupContactsQuery,
  createContactMutation,
  updateContactMutation,
};
</script>

<template>
  <contact-form
    v-if="!isLoading"
    :drawer-open="true"
    :get-query="$options.getGroupContactsQuery"
    :get-query-variables="{ groupFullPath }"
    get-query-node-path="group.contacts"
    :create-mutation="$options.createContactMutation"
    :additional-create-params="{ groupId: groupGraphQLId }"
    :update-mutation="$options.updateContactMutation"
    :existing-model="editingContact"
    :fields="$options.fields"
    :i18n="$options.i18n"
    :is-edit-mode="isEditMode"
  />
</template>
