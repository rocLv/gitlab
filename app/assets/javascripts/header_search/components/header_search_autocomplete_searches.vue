<script>
import {
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlDropdownDivider,
  GlAvatar,
  GlLoadingIcon,
  GlSafeHtmlDirective as SafeHtml,
} from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import highlight from '~/lib/utils/highlight';

const GROUPS = 'Groups';
const PROJECTS = 'Projects';

export default {
  name: 'HeaderSearchAutocompleteSearches',
  components: {
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlDropdownDivider,
    GlAvatar,
    GlLoadingIcon,
  },
  directives: {
    SafeHtml,
  },
  computed: {
    ...mapState(['search', 'loading']),
    ...mapGetters(['autocompleteSearchOptions']),
  },
  methods: {
    highlightedName(val) {
      return highlight(val, this.search);
    },
    showAvatar(data) {
      return Object.prototype.hasOwnProperty.call(data, 'avatar_url');
    },
    avatarSize(data) {
      if (data.category === GROUPS || data.category === PROJECTS) {
        return 32;
      }

      return 16;
    },
  },
};
</script>

<template>
  <div>
    <template v-if="!loading">
      <div v-for="option in autocompleteSearchOptions" :key="option.category">
        <gl-dropdown-divider />
        <gl-dropdown-section-header>{{ option.category }}</gl-dropdown-section-header>
        <gl-dropdown-item
          v-for="(data, index) in option.data"
          :id="`autocomplete-${option.category}-${index}`"
          :key="index"
          tabindex="-1"
          :href="data.url"
        >
          <div class="gl-display-flex gl-align-items-center">
            <gl-avatar
              v-if="showAvatar(data)"
              :src="data.avatar_url"
              :entity-id="data.id"
              :entity-name="data.label"
              :size="avatarSize(data)"
              shape="square"
            />
            <span v-safe-html="highlightedName(data.label)"></span>
          </div>
        </gl-dropdown-item>
      </div>
    </template>
    <gl-loading-icon v-else size="lg" class="my-4" />
  </div>
</template>
