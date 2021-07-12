<script>
import { GlDropdownItem, GlDropdownSectionHeader } from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import { __ } from '~/locale';

export default {
  name: 'HeaderSearchDefaultDropdown',
  i18n: {
    allGitLab: __('All GitLab'),
    issuesAssignedToMe: __('Issues assigned to me'),
    issuesIveCreated: __("Issues I've created"),
    mrAssignedToMe: __('Merge requests assigned to me'),
    mrImReviewer: __("Merge requests that I'm a reviewer"),
    mrIveCreated: __("Merge requests I've created"),
  },
  components: {
    GlDropdownSectionHeader,
    GlDropdownItem,
  },
  computed: {
    ...mapState(['searchContext']),
    ...mapGetters(['scopedIssuesPath', 'scopedMRPath']),
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
    defaultSearchOptions() {
      return [
        {
          title: this.$options.i18n.issuesAssignedToMe,
          url: `${this.scopedIssuesPath}/?assignee_username=${this.userName}`,
        },
        {
          title: this.$options.i18n.issuesIveCreated,
          url: `${this.scopedIssuesPath}/?author_username=${this.userName}`,
        },
        {
          title: this.$options.i18n.mrAssignedToMe,
          url: `${this.scopedMRPath}/?assignee_username=${this.userName}`,
        },
        {
          title: this.$options.i18n.mrImReviewer,
          url: `${this.scopedMRPath}/?reviewer_username=${this.userName}`,
        },
        {
          title: this.$options.i18n.mrIveCreated,
          url: `${this.scopedMRPath}/?author_username=${this.userName}`,
        },
      ];
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
