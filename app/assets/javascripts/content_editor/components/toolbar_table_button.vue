<script>
import { GlDropdown, GlDropdownItem, GlDropdownDivider, GlDropdownForm } from '@gitlab/ui';
import { selectedRect as getSelectedRect } from 'prosemirror-tables';
import { __, sprintf } from '~/locale';
import Table from '../extensions/table';
import TableHeader from '../extensions/table_header';
import { clamp } from '../services/utils';
import EditorStateObserver from './editor_state_observer.vue';

const MIN_ROWS = 3;
const MIN_COLS = 3;
const MAX_ROWS = 8;
const MAX_COLS = 8;

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlDropdownForm,
    EditorStateObserver,
  },
  inject: ['tiptapEditor'],
  data() {
    return {
      maxRows: MIN_ROWS,
      maxCols: MIN_COLS,
      rows: 1,
      cols: 1,
      isActive: false,
      isHeaderActive: false,
      selectedRect: null,
    };
  },
  computed: {
    isFirstRow() {
      return this.selectedRect?.top === 0;
    },
    totalRows() {
      return this.selectedRect?.map.height;
    },
    totalCols() {
      return this.selectedRect?.map.width;
    },
    selectedRows() {
      return Math.abs(this.selectedRect?.top - this.selectedRect?.bottom);
    },
    selectedCols() {
      return Math.abs(this.selectedRect?.left - this.selectedRect?.right);
    },
  },
  methods: {
    list(n) {
      return new Array(n).fill().map((_, i) => i + 1);
    },
    updateTableState({ editor }) {
      this.isActive = editor.isActive(Table.name);
      this.isHeaderActive = editor.isActive(TableHeader.name);
      if (this.isActive) this.selectedRect = getSelectedRect(editor.state);
    },
    setRowsAndCols(rows, cols) {
      this.rows = rows;
      this.cols = cols;
      this.maxRows = clamp(rows + 1, MIN_ROWS, MAX_ROWS);
      this.maxCols = clamp(cols + 1, MIN_COLS, MAX_COLS);
    },
    resetState() {
      this.rows = 1;
      this.cols = 1;
    },
    insertTable() {
      this.runCommand('insertTable', { rows: this.rows, cols: this.cols, withHeaderRow: true });
      this.resetState();

      this.$emit('execute', { contentType: Table.name });
    },
    runCommand(name, params = {}) {
      this.tiptapEditor.chain().focus()[name](params).run();
    },
    getButtonLabel(rows, cols) {
      return sprintf(__('Insert a %{rows}x%{cols} table.'), { rows, cols });
    },
  },
};
</script>
<template>
  <editor-state-observer @transaction="updateTableState">
    <gl-dropdown
      :toggle-class="{ active: isActive }"
      size="small"
      category="tertiary"
      icon="table"
      class="table-dropdown"
      @mousedown.prevent=""
      @click.prevent=""
    >
      <gl-dropdown-form v-if="!isActive" class="gl-px-3!">
        <div v-for="r of list(maxRows)" :key="r" class="gl-display-flex">
          <div
            v-for="c of list(maxCols)"
            :key="c"
            :data-testid="`table-${r}-${c}`"
            :class="{ active: r <= rows && c <= cols }"
            :aria-label="getButtonLabel(r, c)"
            class="table-creator-grid-item js-table-creator-grid-item"
            @mouseover="setRowsAndCols(r, c)"
            @click="insertTable()"
          ></div>
        </div>
        <gl-dropdown-divider class="gl-my-3! gl-mx-n4!" />
        <div class="gl-px-1">
          {{ getButtonLabel(rows, cols) }}
        </div>
      </gl-dropdown-form>
      <template v-if="isActive">
        <gl-dropdown-item @click="runCommand('addColumnBefore')">
          {{ __('Insert column before') }}
        </gl-dropdown-item>
        <gl-dropdown-item @click="runCommand('addColumnAfter')">
          {{ __('Insert column after') }}
        </gl-dropdown-item>
        <gl-dropdown-item v-if="!isHeaderActive" @click="runCommand('addRowBefore')">
          {{ __('Insert row before') }}
        </gl-dropdown-item>
        <gl-dropdown-item @click="runCommand('addRowAfter')">
          {{ __('Insert row after') }}
        </gl-dropdown-item>
        <gl-dropdown-item v-if="isFirstRow" @click="runCommand('toggleHeaderRow')">
          {{ __('Toggle header row') }}
        </gl-dropdown-item>
        <gl-dropdown-divider />
        <gl-dropdown-item v-if="totalRows > 1" @click="runCommand('deleteRow')">
          {{ n__('Delete row', 'Delete %d rows', selectedRows) }}
        </gl-dropdown-item>
        <gl-dropdown-item v-if="totalCols > 1" @click="runCommand('deleteColumn')">
          {{ n__('Delete column', 'Delete %d columns', selectedCols) }}
        </gl-dropdown-item>
        <gl-dropdown-item @click="runCommand('deleteTable')">
          {{ __('Delete table') }}
        </gl-dropdown-item>
      </template>
    </gl-dropdown>
  </editor-state-observer>
</template>
