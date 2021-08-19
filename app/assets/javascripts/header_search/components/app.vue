<script>
import { GlSearchBoxByType } from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { TAB_KEY_CODE } from '~/lib/utils/keycodes';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { FIRST_DROPDOWN_INDEX, SEARCH_BOX_INDEX, DROPDOWN_SELECTOR } from '../constants';
import DropdownKeyboardNavigation from './dropdown_keyboard_navigation.vue';
import HeaderSearchAutocompleteSearches from './header_search_autocomplete_searches.vue';
import HeaderSearchDefaultSearches from './header_search_default_searches.vue';
import HeaderSearchScopedSearches from './header_search_scoped_searches.vue';

export default {
  name: 'HeaderSearchApp',
  i18n: {
    searchPlaceholder: __('Search or jump to...'),
  },
  components: {
    GlSearchBoxByType,
    DropdownKeyboardNavigation,
    HeaderSearchDefaultSearches,
    HeaderSearchScopedSearches,
    HeaderSearchAutocompleteSearches,
  },
  data() {
    return {
      showDropdown: false,
      currentFocusIndex: SEARCH_BOX_INDEX,
    };
  },
  computed: {
    ...mapState(['search']),
    ...mapGetters(['searchQuery', 'searchOptionsLength']),
    searchText: {
      get() {
        return this.search;
      },
      set(value) {
        this.setSearch(value);
      },
    },
    showSearchDropdown() {
      return this.showDropdown && gon?.current_username;
    },
    showDefaultSearches() {
      return !this.searchText;
    },
    defaultIndex() {
      if (this.showDefaultSearches) {
        return SEARCH_BOX_INDEX;
      }

      return FIRST_DROPDOWN_INDEX;
    },
  },
  watch: {
    currentFocusIndex(idx, prevIdx) {
      const dropdownItemsEl = this.$refs.headerDropdown.querySelectorAll(DROPDOWN_SELECTOR);

      const searchBoxInputEl = this.$refs.searchBox.$el.querySelector('input');

      if (!dropdownItemsEl) {
        return;
      }

      dropdownItemsEl[prevIdx]?.classList.remove('gl-bg-gray-50!');

      if (idx === SEARCH_BOX_INDEX) {
        searchBoxInputEl.focus();
        searchBoxInputEl.removeAttribute('aria-activedescendant');
      } else {
        this.focusElement(dropdownItemsEl[idx]);
      }
    },
  },
  beforeDestroy() {
    this.removeDropdownEventListeners();
  },
  methods: {
    ...mapActions(['setSearch', 'fetchAutocompleteOptions']),
    addDropdownEventListeners() {
      document.addEventListener('click', this.handleDocumentClick);
      document.addEventListener('keydown', this.handleKeydown);
    },
    removeDropdownEventListeners() {
      document.removeEventListener('click', this.handleDocumentClick);
      document.removeEventListener('keydown', this.handleKeydown);
    },
    handleDocumentClick(event) {
      // If we clicked anywhere not on the dropdown, close it
      if (
        event.target !== this.$refs.headerSearch &&
        !this.$refs.headerSearch.contains(event.target)
      ) {
        this.closeDropdown();
      }
    },
    handleKeydown(event) {
      // Otherwise the dropdown stays open when tab away from it.
      if (event.keyCode === TAB_KEY_CODE) {
        this.closeDropdown();
      }
    },
    focusElement(element) {
      const searchBoxInputEl = this.$refs.searchBox.$el.querySelector('input');

      // Simulates :focus
      element.classList.add('gl-bg-gray-50!');
      // This ensures the items stays in the viewport if we arrow down past the overflow
      element.scrollIntoView(false);
      // This tells assistive technology what is focused in a menu
      searchBoxInputEl.setAttribute('aria-activedescendant', element.id);
    },
    openDropdown() {
      if (this.showDropdown) {
        return;
      }

      this.showDropdown = true;
      this.addDropdownEventListeners();
    },
    closeDropdown() {
      if (!this.showDropdown) {
        return;
      }

      this.showDropdown = false;
      this.removeDropdownEventListeners();
    },
    submitSearch() {
      // Handles if user hits enter on clear icon
      if (!this.showSearchDropdown) {
        return null;
      }

      if (this.currentFocusIndex >= FIRST_DROPDOWN_INDEX) {
        const dropdownItemsEl = this.$refs.headerDropdown.querySelectorAll(DROPDOWN_SELECTOR);

        return dropdownItemsEl[this.currentFocusIndex].click();
      }

      return visitUrl(this.searchQuery);
    },
    getAutocompleteOptions() {
      if (!this.searchText) {
        return;
      }

      this.fetchAutocompleteOptions();
    },
  },
  SEARCH_BOX_INDEX,
};
</script>

<template>
  <section ref="headerSearch" class="header-search gl-relative">
    <gl-search-box-by-type
      ref="searchBox"
      v-model="searchText"
      autocomplete="off"
      :placeholder="$options.i18n.searchPlaceholder"
      :debounce="500"
      @focus="openDropdown"
      @click="openDropdown"
      @input="getAutocompleteOptions"
      @keydown.enter="submitSearch"
      @keydown.esc="closeDropdown"
    />
    <div
      v-if="showSearchDropdown"
      class="header-search-dropdown-menu gl-overflow-y-auto gl-absolute gl-left-0 gl-z-index-1 gl-w-full gl-bg-white gl-border-1 gl-rounded-base gl-border-solid gl-border-gray-200 gl-shadow-x0-y2-b4-s0"
    >
      <div ref="headerDropdown" class="header-search-dropdown-content gl-overflow-y-auto gl-py-2">
        <dropdown-keyboard-navigation
          v-model="currentFocusIndex"
          :max="searchOptionsLength - 1"
          :min="$options.SEARCH_BOX_INDEX"
          :default-index="defaultIndex"
        />
        <header-search-default-searches v-if="showDefaultSearches" />
        <template v-else>
          <header-search-scoped-searches />
          <header-search-autocomplete-searches />
        </template>
      </div>
    </div>
  </section>
</template>
