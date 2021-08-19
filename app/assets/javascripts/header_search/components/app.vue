<script>
import { GlSearchBoxByType } from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { TAB_KEY_CODE } from '~/lib/utils/keycodes';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
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
      currentFocusIndex: -1,
    };
  },
  computed: {
    ...mapState(['search']),
    ...mapGetters(['searchQuery', 'defaultSearchOptions', 'searchOptionsLength']),
    searchText: {
      get() {
        return this.search;
      },
      set(value) {
        this.setSearch(value);
      },
    },
    userName() {
      return gon.current_username;
    },
    showSearchDropdown() {
      return this.showDropdown && this.userName;
    },
    showDefaultSearches() {
      return !this.searchText;
    },
  },
  watch: {
    currentFocusIndex(idx, prevIdx) {
      const dropdownItemsEl = this.$refs.headerDropdown.querySelectorAll(
        '.gl-new-dropdown-item > a',
      );

      if (!dropdownItemsEl) {
        return;
      }

      // -1 Index is the search bar
      dropdownItemsEl[prevIdx]?.classList.remove('gl-bg-gray-50!');
      this.focusElement(dropdownItemsEl[idx]);
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

      this.currentFocusIndex = -1;
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

      if (this.currentFocusIndex >= 0) {
        const dropdownItemsEl = this.$refs.headerDropdown.querySelectorAll(
          '.gl-new-dropdown-item > a',
        );

        return dropdownItemsEl[this.currentFocusIndex].click();
      }

      return visitUrl(this.searchQuery);
    },
    getAutocompleteOptions() {
      this.currentFocusIndex = -1;

      if (!this.searchText) {
        return;
      }

      this.fetchAutocompleteOptions();

      this.$nextTick(() => {
        // We focus the first element when a search term is present
        this.handleArrowDown();
      });
    },
  },
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
      class="header-search-dropdown-menu dropdown-content-faded-mask gl-overflow-y-auto gl-absolute gl-left-0 gl-z-index-1 gl-w-full gl-bg-white gl-border-1 gl-rounded-base gl-border-solid gl-border-gray-200 gl-shadow-x0-y2-b4-s0"
    >
      <div
        ref="headerDropdown"
        class="header-search-dropdown-content gl-overflow-y-auto gl-pt-2 gl-pb-5"
      >
        <dropdown-keyboard-navigation v-model="currentFocusIndex" :max="searchOptionsLength - 1" />
        <header-search-default-searches v-if="showDefaultSearches" />
        <template v-else>
          <header-search-scoped-searches />
          <header-search-autocomplete-searches />
        </template>
      </div>
    </div>
  </section>
</template>
