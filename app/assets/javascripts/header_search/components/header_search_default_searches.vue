<script>
import { GlDropdownItem, GlDropdownSectionHeader } from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import { __ } from '~/locale';

export default {
  name: 'HeaderSearchDefaultDropdown',
  i18n: {
    allGitLab: __('All GitLab'),
  },
  components: {
    GlDropdownSectionHeader,
    GlDropdownItem,
  },
  computed: {
    ...mapState(['searchContext']),
    ...mapGetters(['scopedIssuesPath', 'scopedMRPath', 'defaultSearchOptions']),
    userName() {
      return gon.current_username;
    },
    sectionHeader() {
      if (this.searchContext.project) {
        return this.searchContext.project.name;
      }

      if (this.searchContext.group) {
        return this.searchContext.group.name;
      }

      return this.$options.i18n.allGitLab;
    },
  },
};
</script>

<template>
  <div>
    <gl-dropdown-section-header>{{ sectionHeader }}</gl-dropdown-section-header>
    <gl-dropdown-item
      v-for="(option, index) in defaultSearchOptions"
      :id="`default-${index}`"
      :key="index"
      tabindex="0"
      :href="option.url"
    >
      {{ option.title }}
    </gl-dropdown-item>
  </div>
</template>
