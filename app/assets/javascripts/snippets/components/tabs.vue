<script>
import { GlTabs, GlTab, GlBadge } from '@gitlab/ui';
import { redirectTo, getParameterValues } from '~/lib/utils/url_utility';

export default {
  name: 'SnippetsTabs',
  components: {
    GlTabs,
    GlTab,
    GlBadge,
  },
  inject: {
    tabs: {
      default: [],
    },
  },
  computed: {
    selectedTab() {
      const [value] = getParameterValues('scope');

      return this.tabs.map((tab) => tab.scope).indexOf(value);
    },
  },
  methods: {
    onTabClick(link) {
      redirectTo(link);
    },
  },
};
</script>
<template>
  <gl-tabs
    :value="selectedTab"
    class="gl-display-flex gl-flex-grow-1"
    nav-class="gl-border-bottom-0"
  >
    <gl-tab v-for="tab in tabs" :key="tab.title" @click="onTabClick(tab.link)">
      <template #title>
        <span>{{ tab.title }}</span>
        <gl-badge size="sm" class="gl-tab-counter-badge">{{ tab.count }}</gl-badge>
      </template>
    </gl-tab>
  </gl-tabs>
</template>
