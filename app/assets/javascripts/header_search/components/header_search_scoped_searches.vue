<script>
import { GlDropdownItem } from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import { __ } from '~/locale';

export default {
  name: 'HeaderSearchScopedSearches',
  i18n: {
    inAllGitLab: __('in all GitLab'),
    inGroup: __('in group'),
    inProject: __('in project'),
  },
  components: {
    GlDropdownItem,
  },
  computed: {
    ...mapState(['searchContext', 'search']),
    ...mapGetters(['projectUrl', 'groupUrl', 'allUrl']),
    scopedSearchOptions() {
      const options = [];

      if (this.searchContext.project) {
        options.push({
          scope: this.searchContext.project.name,
          description: this.$options.i18n.inProject,
          url: this.projectUrl,
        });
      }

      if (this.searchContext.group) {
        options.push({
          scope: this.searchContext.group.name,
          description: this.$options.i18n.inGroup,
          url: this.groupUrl,
        });
      }

      options.push({
        description: this.$options.i18n.inAllGitLab,
        url: this.allUrl,
      });

      return options;
    },
  },
};
</script>

<template>
  <div>
    <gl-dropdown-item
      v-for="(option, index) in scopedSearchOptions"
      :id="`scoped-${index}`"
      :key="index"
      :href="option.url"
    >
      "<span class="gl-font-weight-bold">{{ search }}</span
      >" {{ option.description }}
      <span v-if="option.scope" class="gl-font-style-italic">{{ option.scope }}</span>
    </gl-dropdown-item>
  </div>
</template>
