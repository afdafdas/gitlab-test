<script>
import {
  GlSearchBoxByType,
  GlOutsideDirective as Outside,
  GlIcon,
  GlToken,
  GlTooltipDirective,
  GlResizeObserverDirective,
} from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { debounce } from 'lodash';
import { visitUrl } from '~/lib/utils/url_utility';
import { truncate } from '~/lib/utils/text_utility';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { s__, sprintf } from '~/locale';
import Tracking from '~/tracking';
import DropdownKeyboardNavigation from '~/vue_shared/components/dropdown_keyboard_navigation.vue';
import {
  FIRST_DROPDOWN_INDEX,
  SEARCH_BOX_INDEX,
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
  SEARCH_SHORTCUTS_MIN_CHARACTERS,
  SCOPE_TOKEN_MAX_LENGTH,
  INPUT_FIELD_PADDING,
  IS_SEARCHING,
  IS_FOCUSED,
  IS_NOT_FOCUSED,
} from '../constants';
import HeaderSearchAutocompleteItems from './header_search_autocomplete_items.vue';
import HeaderSearchDefaultItems from './header_search_default_items.vue';
import HeaderSearchScopedItems from './header_search_scoped_items.vue';

export default {
  name: 'HeaderSearchApp',
  i18n: {
    searchGitlab: s__('GlobalSearch|Search GitLab'),
    searchInputDescribeByNoDropdown: s__(
      'GlobalSearch|Type and press the enter key to submit search.',
    ),
    searchInputDescribeByWithDropdown: s__(
      'GlobalSearch|Type for new suggestions to appear below.',
    ),
    searchDescribedByDefault: s__(
      'GlobalSearch|%{count} default results provided. Use the up and down arrow keys to navigate search results list.',
    ),
    searchDescribedByUpdated: s__(
      'GlobalSearch|Results updated. %{count} results available. Use the up and down arrow keys to navigate search results list, or ENTER to submit.',
    ),
    searchResultsLoading: s__('GlobalSearch|Search results are loading'),
    searchResultsScope: s__('GlobalSearch|in %{scope}'),
    kbdHelp: sprintf(
      s__('GlobalSearch|Use the shortcut key %{kbdOpen}/%{kbdClose} to start a search'),
      { kbdOpen: '<kbd>', kbdClose: '</kbd>' },
      false,
    ),
  },
  directives: { Outside, GlTooltip: GlTooltipDirective, GlResizeObserverDirective },
  components: {
    GlSearchBoxByType,
    HeaderSearchDefaultItems,
    HeaderSearchScopedItems,
    HeaderSearchAutocompleteItems,
    DropdownKeyboardNavigation,
    GlIcon,
    GlToken,
  },
  data() {
    return {
      showDropdown: false,
      isFocused: false,
      currentFocusIndex: SEARCH_BOX_INDEX,
    };
  },
  computed: {
    ...mapState(['search', 'loading', 'searchContext']),
    ...mapGetters(['searchQuery', 'searchOptions']),
    searchText: {
      get() {
        return this.search;
      },
      set(value) {
        this.setSearch(value);
      },
    },
    currentFocusedOption() {
      return this.searchOptions[this.currentFocusIndex];
    },
    currentFocusedId() {
      return this.currentFocusedOption?.html_id;
    },
    isLoggedIn() {
      return Boolean(gon?.current_username);
    },
    showSearchDropdown() {
      if (!this.showDropdown || !this.isLoggedIn) {
        return false;
      }
      return this.searchOptions?.length > 0;
    },
    showDefaultItems() {
      return !this.searchText;
    },
    searchTermOverMin() {
      return this.searchText?.length > SEARCH_SHORTCUTS_MIN_CHARACTERS;
    },
    defaultIndex() {
      if (this.showDefaultItems) {
        return SEARCH_BOX_INDEX;
      }
      return FIRST_DROPDOWN_INDEX;
    },

    searchInputDescribeBy() {
      if (this.isLoggedIn) {
        return this.$options.i18n.searchInputDescribeByWithDropdown;
      }
      return this.$options.i18n.searchInputDescribeByNoDropdown;
    },
    dropdownResultsDescription() {
      if (!this.showSearchDropdown) {
        return ''; // This allows aria-live to see register an update when the dropdown is shown
      }

      if (this.showDefaultItems) {
        return sprintf(this.$options.i18n.searchDescribedByDefault, {
          count: this.searchOptions.length,
        });
      }

      return this.loading
        ? this.$options.i18n.searchResultsLoading
        : sprintf(this.$options.i18n.searchDescribedByUpdated, {
            count: this.searchOptions.length,
          });
    },
    searchBarClasses() {
      return {
        [IS_SEARCHING]: this.searchTermOverMin,
        [IS_FOCUSED]: this.isFocused,
        [IS_NOT_FOCUSED]: !this.isFocused,
      };
    },
    showScopeHelp() {
      return this.searchTermOverMin && this.isFocused;
    },
    searchBarItem() {
      return this.searchOptions?.[0];
    },
    infieldHelpContent() {
      return this.searchBarItem?.scope || this.searchBarItem?.description;
    },
    infieldHelpIcon() {
      return this.searchBarItem?.icon;
    },
    scopeTokenTitle() {
      return sprintf(this.$options.i18n.searchResultsScope, {
        scope: this.infieldHelpContent,
      });
    },
  },
  methods: {
    ...mapActions(['setSearch', 'fetchAutocompleteOptions', 'clearAutocomplete']),
    openDropdown() {
      this.showDropdown = true;

      // check isFocused state to avoid firing duplicate events
      if (!this.isFocused) {
        this.isFocused = true;
        this.$emit('expandSearchBar', true);

        Tracking.event(undefined, 'focus_input', {
          label: 'global_search',
          property: 'top_navigation',
        });
      }
    },
    closeDropdown() {
      this.showDropdown = false;
    },
    collapseAndCloseSearchBar() {
      // we need a delay on this method
      // for the search bar not to remove
      // the clear button from dom
      // and register clicks on dropdown items
      setTimeout(() => {
        this.showDropdown = false;
        this.isFocused = false;
        this.$emit('collapseSearchBar');

        Tracking.event(undefined, 'blur_input', {
          label: 'global_search',
          property: 'top_navigation',
        });
      }, 200);
    },
    submitSearch() {
      if (this.search?.length <= SEARCH_SHORTCUTS_MIN_CHARACTERS && this.currentFocusIndex < 0) {
        return null;
      }
      return visitUrl(this.currentFocusedOption?.url || this.searchQuery);
    },
    getAutocompleteOptions: debounce(function debouncedSearch(searchTerm) {
      this.openDropdown();
      if (!searchTerm) {
        this.clearAutocomplete();
      } else {
        this.fetchAutocompleteOptions();
      }
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
    getTruncatedScope(scope) {
      return truncate(scope, SCOPE_TOKEN_MAX_LENGTH);
    },
    observeTokenWidth({ contentRect: { width } }) {
      const inputField = this.$refs?.searchInputBox?.$el?.querySelector('input');
      if (!inputField) {
        return;
      }
      inputField.style.paddingRight = `${width + INPUT_FIELD_PADDING}px`;
    },
  },
  SEARCH_BOX_INDEX,
  FIRST_DROPDOWN_INDEX,
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
};
</script>

<template>
  <form
    v-outside="closeDropdown"
    role="search"
    :aria-label="$options.i18n.searchGitlab"
    class="header-search gl-relative gl-rounded-base gl-w-full"
    :class="searchBarClasses"
    data-testid="header-search-form"
  >
    <gl-search-box-by-type
      id="search"
      ref="searchInputBox"
      v-model="searchText"
      role="searchbox"
      class="gl-z-index-1"
      data-qa-selector="search_term_field"
      autocomplete="off"
      :placeholder="$options.i18n.searchGitlab"
      :aria-activedescendant="currentFocusedId"
      :aria-describedby="$options.SEARCH_INPUT_DESCRIPTION"
      @focus="openDropdown"
      @click="openDropdown"
      @blur="collapseAndCloseSearchBar"
      @input="getAutocompleteOptions"
      @keydown.enter.stop.prevent="submitSearch"
      @keydown.esc.stop.prevent="closeDropdown"
    />
    <gl-token
      v-if="showScopeHelp"
      v-gl-resize-observer-directive="observeTokenWidth"
      class="in-search-scope-help"
      :view-only="true"
      :title="scopeTokenTitle"
      ><gl-icon
        v-if="infieldHelpIcon"
        class="gl-mr-2"
        :aria-label="infieldHelpContent"
        :name="infieldHelpIcon"
        :size="16"
      />{{
        getTruncatedScope(
          sprintf($options.i18n.searchResultsScope, {
            scope: infieldHelpContent,
          }),
        )
      }}
    </gl-token>
    <kbd
      v-show="!isFocused"
      v-gl-tooltip.bottom.hover.html
      class="gl-absolute gl-right-3 gl-top-0 gl-z-index-1 keyboard-shortcut-helper"
      :title="$options.i18n.kbdHelp"
      >/</kbd
    >
    <span :id="$options.SEARCH_INPUT_DESCRIPTION" role="region" class="gl-sr-only">{{
      searchInputDescribeBy
    }}</span>
    <span
      role="region"
      :data-testid="$options.SEARCH_RESULTS_DESCRIPTION"
      class="gl-sr-only"
      aria-live="polite"
      aria-atomic="true"
    >
      {{ dropdownResultsDescription }}
    </span>
    <div
      v-if="showSearchDropdown"
      data-testid="header-search-dropdown-menu"
      class="header-search-dropdown-menu gl-overflow-y-auto gl-absolute gl-w-full gl-bg-white gl-border-1 gl-rounded-base gl-border-solid gl-border-gray-200 gl-shadow-x0-y2-b4-s0 gl-mt-3"
    >
      <div class="header-search-dropdown-content gl-py-2">
        <dropdown-keyboard-navigation
          v-model="currentFocusIndex"
          :max="searchOptions.length - 1"
          :min="$options.FIRST_DROPDOWN_INDEX"
          :default-index="defaultIndex"
          @tab="closeDropdown"
        />
        <header-search-default-items
          v-if="showDefaultItems"
          :current-focused-option="currentFocusedOption"
        />
        <template v-else>
          <header-search-scoped-items
            v-if="searchTermOverMin"
            :current-focused-option="currentFocusedOption"
          />
          <header-search-autocomplete-items :current-focused-option="currentFocusedOption" />
        </template>
      </div>
    </div>
  </form>
</template>
