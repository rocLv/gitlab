<script>
import { GlButton } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapActions, mapGetters } from 'vuex';

import searchIterationQuery from 'ee/issues/list/queries/search_iterations.query.graphql';
import { n__, s__ } from '~/locale';
import { TYPE_ITERATION } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import DropdownWidget from '~/vue_shared/components/dropdown/dropdown_widget/dropdown_widget.vue';

import { IterationsPreset, ANY_ITERATION, CURRENT_ITERATION } from '../constants';

export default {
  IterationsPreset,
  components: {
    GlButton,
    DropdownWidget,
  },
  inject: ['fullPath'],
  props: {
    board: {
      type: Object,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      search: '',
      iterations: [],
      cadences: [],
      selected: this.board.iteration
        ? {
            ...this.board.iteration,
            id: convertToGraphQLId(TYPE_ITERATION, getIdFromGraphQLId(this.board.iteration?.id)),
          }
        : null,
      isEditing: false,
      isDropdownShowing: false,
    };
  },
  apollo: {
    iterations: {
      query: searchIterationQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          search: this.search,
          first: 20,
          isProject: this.isProjectBoard,
        };
      },
      skip() {
        return !this.isEditing;
      },
      update(data) {
        const boardType = this.isProject ? 'project' : 'group';
        return data[boardType]?.iterations?.nodes || [];
      },
      error() {
        this.setError({ message: this.$options.i18n.errorSearchingIterations });
      },
    },
  },
  computed: {
    ...mapGetters(['isProjectBoard']),
    anyIteration() {
      return this.selected.id === ANY_ITERATION.id;
    },
    iterationTitle() {
      return this.anyIteration ? ANY_ITERATION.title : this.selected.title;
    },
    iterationTitleClass() {
      return this.anyIteration ? 'gl-text-gray-500' : 'gl-font-weight-bold';
    },
    isLoading() {
      return this.$apollo.queries.iterations.loading;
    },
    iterationsByCadence() {
      const cadences = [];
      this.iterations.forEach((iteration) => {
        if (!iteration.iterationCadence) {
          return;
        }
        const { title, durationInWeeks, id } = iteration.iterationCadence;
        const cadenceIteration = {
          key: `${iteration.iterationCadence.id}-${iteration.id}`,
          id: iteration.id,
          title: iteration.title,
          iterationCadenceId: id,
        };
        const cadence = cadences.find((cad) => cad.title === title);
        if (cadence) {
          cadence.options.push(cadenceIteration);
        } else {
          const durationText = durationInWeeks
            ? n__('Every week', 'Every %d weeks', durationInWeeks)
            : null;
          const currentIterationOption = {
            key: `${id}-${CURRENT_ITERATION.id}`,
            iterationCadenceId: id,
            ...CURRENT_ITERATION,
          };
          cadences.push({
            id,
            title,
            secondaryText: durationText,
            options: [currentIterationOption, cadenceIteration],
          });
        }
      });
      return cadences;
    },
  },
  created() {
    if (isEmpty(this.board.iteration)) {
      this.selected = ANY_ITERATION;
    }
  },
  methods: {
    ...mapActions(['setError']),
    selectIteration(iteration) {
      this.selected = iteration;
      this.toggleEdit();
      this.$emit('set-iteration', iteration);
    },
    toggleEdit() {
      if (!this.isEditing && !this.isDropdownShowing) {
        this.isEditing = true;
        this.showDropdown();
      } else {
        this.isEditing = false;
        this.isDropdownShowing = false;
      }
    },
    showDropdown() {
      this.$refs.editDropdown.showDropdown();
      this.isDropdownShowing = true;
    },
    hideDropdown() {
      this.isEditing = false;
    },
    setSearch(search) {
      this.search = search;
    },
  },
  i18n: {
    label: s__('BoardScope|Iteration'),
    errorSearchingIterations: s__(
      'BoardScope|An error occurred while getting iterations, please try again.',
    ),
    errorSearchingCadences: s__(
      'BoardScope|An error occurred while getting iteration cadences, please try again.',
    ),
    searchIterations: s__('BoardScope|Search iterations'),
    selectIteration: s__('BoardScope|Select iteration'),
    edit: s__('BoardScope|Edit'),
  },
};
</script>

<template>
  <div class="block iteration">
    <div class="title gl-mb-3">
      {{ $options.i18n.label }}
      <gl-button
        v-if="canEdit"
        category="tertiary"
        size="small"
        class="edit-link float-right"
        @click="toggleEdit"
      >
        {{ $options.i18n.edit }}
      </gl-button>
    </div>
    <div v-if="!isEditing" :class="iterationTitleClass" data-testid="selected-iteration">
      {{ iterationTitle }}
    </div>

    <dropdown-widget
      v-show="isEditing"
      ref="editDropdown"
      :select-text="$options.i18n.selectIteration"
      :search-text="$options.i18n.searchIterations"
      :preset-options="$options.IterationsPreset"
      :grouped-options="iterationsByCadence"
      :is-loading="isLoading"
      :selected="selected"
      :search-term="search"
      @hide="hideDropdown"
      @set-option="selectIteration"
      @set-search="setSearch"
    />
  </div>
</template>
