<script>
import { isEqual, xor, keyBy } from 'lodash';
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';

export default {
  components: { FilterBody, FilterItem },
  props: {
    filter: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      selectedIds: this.filter.defaultIds,
    };
  },
  computed: {
    options() {
      return this.filter.options;
    },
    // Used for O(1) lookups to convert IDs to option objects.
    optionsMap() {
      return keyBy(this.options, 'id');
    },
    selectedSet() {
      return new Set(this.selectedIds);
    },
    hasSelectedOptions() {
      return this.selectedIds.length;
    },
    selectedOptions() {
      return this.hasSelectedOptions
        ? this.selectedIds.map((id) => this.optionsMap[id])
        : [this.filter.allOption];
    },
    allId() {
      return this.filter.allOption.id;
    },
    filterObject() {
      // This is used as a variable for the vulnerability list's GraphQL query.
      return { [this.filter.id]: this.selectedIds };
    },
    querystringIds() {
      const ids = this.$route?.query[this.filter.id] || [];
      const idArray = Array.isArray(ids) ? ids : [ids];
      // Sort the IDs and remove duplicates.
      return [...new Set(idArray.sort())];
    },
  },
  watch: {
    '$route.query': {
      immediate: true,
      handler() {
        this.processQuerystringIds();
      },
    },
    selectedIds: {
      immediate: true,
      handler() {
        this.emitFilterChanged(this.filterObject);
      },
    },
  },
  methods: {
    toggleOption({ id }) {
      // Toggle the ID's existence in the array.
      this.selectedIds = xor(this.selectedIds, [id]);
      this.updateQuerystring();
    },
    deselectAllOptions() {
      this.selectedIds = [];
      this.updateQuerystring();
    },
    updateQuerystring() {
      const ids = this.hasSelectedOptions ? this.selectedIds : [this.allId];
      // To avoid a console error, don't update the querystring if it's the same as the current one.
      if (!this.$router || isEqual(this.querystringIds, ids)) {
        return;
      }

      const query = { ...this.$route.query, [this.filter.id]: ids };
      this.$router.push({ query });
    },
    isSelected({ id }) {
      return this.selectedSet.has(id);
    },
    processQuerystringIds() {
      // If the special All option is in the querystring, nothing should be selected, even if there
      // are other IDs in the querystring.
      if (this.querystringIds.includes(this.allId)) {
        this.selectedIds = [];
      } else {
        // Valid IDs are ones that match the ID of a selectable option.
        const validIds = this.querystringIds.filter((id) => Boolean(this.optionsMap[id]));
        // If none of the querystring IDs were valid, use the default IDs.
        this.selectedIds = validIds.length ? validIds : this.filter.defaultIds;
      }
    },
    emitFilterChanged(data) {
      this.$emit('filter-changed', data);
    },
  },
};
</script>

<template>
  <filter-body :name="filter.name" :selected-options="selectedOptions">
    <filter-item
      v-if="filter.allOption"
      :is-checked="!hasSelectedOptions"
      :text="filter.allOption.name"
      data-testid="allOption"
      @click="deselectAllOptions"
    />
    <filter-item
      v-for="option in options"
      :key="option.id"
      :is-checked="isSelected(option)"
      :text="option.name"
      :data-testid="`${filter.id}:${option.id}`"
      @click="toggleOption(option)"
    />
  </filter-body>
</template>
