<script>
import { GlDropdownDivider } from '@gitlab/ui';
import { xor } from 'lodash';
import { activityOptions } from 'ee/security_dashboard/helpers';
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';
import SimpleFilter from './simple_filter.vue';

const { NO_ACTIVITY, WITH_ISSUES, NO_LONGER_DETECTED } = activityOptions;

export default {
  components: { FilterBody, FilterItem, GlDropdownDivider },
  extends: SimpleFilter,
  computed: {
    filterObject() {
      // This is the object used to update the GraphQL query.
      return {
        hasIssues: this.hasSelectedOptions ? this.isSelected(WITH_ISSUES) : undefined,
        hasResolution: this.hasSelectedOptions ? this.isSelected(NO_LONGER_DETECTED) : undefined,
      };
    },
  },
  methods: {
    toggleOption({ id }) {
      if (id === NO_ACTIVITY.id) {
        // The No Activity option is exclusive, it can only be selected by itself or not selected.
        this.selectedIds = this.isSelected(NO_ACTIVITY) ? [] : [NO_ACTIVITY.id];
      } else {
        const ids = this.selectedIds.filter((selectedId) => selectedId !== NO_ACTIVITY.id);
        // Toggle the option's existence in the array.
        this.selectedIds = xor(ids, [id]);
      }

      this.updateQuerystring();
    },
  },
  NO_ACTIVITY,
  multiselectOptions: [WITH_ISSUES, NO_LONGER_DETECTED],
};
</script>

<template>
  <filter-body :name="filter.name" :selected-options="selectedOptions">
    <filter-item
      :is-checked="!hasSelectedOptions"
      :text="filter.allOption.name"
      :data-testid="`option:${filter.allOption.name}`"
      @click="deselectAllOptions"
    />
    <filter-item
      :is-checked="isSelected($options.NO_ACTIVITY)"
      :text="$options.NO_ACTIVITY.name"
      :data-testid="`option:${$options.NO_ACTIVITY.name}`"
      @click="toggleOption($options.NO_ACTIVITY)"
    />
    <gl-dropdown-divider />
    <filter-item
      v-for="option in $options.multiselectOptions"
      :key="option.name"
      :is-checked="isSelected(option)"
      :text="option.name"
      :data-testid="`option:${option.name}`"
      @click="toggleOption(option)"
    />
  </filter-body>
</template>
