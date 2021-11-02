<script>
import { GlAlert } from '@gitlab/ui';
import { isString } from 'lodash';
import { sprintf, n__, __ } from '~/locale';

export default {
  components: {
    GlAlert,
  },
  props: {
    errors: {
      type: Array,
      validator: (errors) => errors.every((error) => isString(error.message)),
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
    truncate: {
      type: Array,
      required: true,
    },
  },
  computed: {
    title() {
      const errorText = n__('error', 'errors', this.errors.length);
      return sprintf(__('The %{type} contains the following %{errorText}:'), {
        type: this.type,
        errorText,
      });
    },
  },
};
</script>

<template>
  <gl-alert
    id="error_explanation"
    class="gl-mb-3"
    variant="danger"
    :dismissible="false"
    :title="title"
  >
    <ul class="gl-pl-5">
      <li v-for="error in errors" :key="error.message">
        <span
          data-testid="form-error"
          :class="{ 'gl-str-truncated': truncate.includes(error.attribute) }"
        >
          {{ error.message }}
        </span>
      </li>
    </ul>
  </gl-alert>
</template>
