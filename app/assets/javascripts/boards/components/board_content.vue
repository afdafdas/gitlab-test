<script>
import { GlAlert } from '@gitlab/ui';
import { breakpoints } from '@gitlab/ui/dist/utils';
import { sortBy, throttle } from 'lodash';
import Draggable from 'vuedraggable';
import { mapState, mapGetters, mapActions } from 'vuex';
import { contentTop } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { formatBoardLists } from 'ee_else_ce/boards/boards_util';
import BoardAddNewColumn from 'ee_else_ce/boards/components/board_add_new_column.vue';
import { defaultSortableOptions } from '~/sortable/constants';
import { DraggableItemTypes, BoardType, listsQuery } from 'ee_else_ce/boards/constants';
import BoardColumn from './board_column.vue';

export default {
  i18n: {
    fetchError: s__(
      'Boards|An error occurred while fetching the board lists. Please reload the page.',
    ),
  },
  draggableItemTypes: DraggableItemTypes,
  components: {
    BoardAddNewColumn,
    BoardColumn,
    BoardContentSidebar: () => import('~/boards/components/board_content_sidebar.vue'),
    EpicBoardContentSidebar: () =>
      import('ee_component/boards/components/epic_board_content_sidebar.vue'),
    EpicsSwimlanes: () => import('ee_component/boards/components/epics_swimlanes.vue'),
    GlAlert,
  },
  inject: [
    'canAdminList',
    'boardType',
    'fullPath',
    'issuableType',
    'isIssueBoard',
    'isEpicBoard',
    'isApolloBoard',
  ],
  props: {
    disabled: {
      type: Boolean,
      required: true,
    },
    boardId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      boardHeight: null,
      boardListsApollo: {},
      apolloError: null,
      updatedBoardId: this.boardId,
    };
  },
  apollo: {
    boardListsApollo: {
      query() {
        return listsQuery[this.issuableType].query;
      },
      variables() {
        return this.queryVariables;
      },
      skip() {
        return !this.isApolloBoard;
      },
      update(data) {
        const { lists } = data[this.boardType].board;
        return formatBoardLists(lists);
      },
      result() {
        // this allows us to delay fetching lists when we switch a board to fetch the actual board lists
        // instead of fetching lists for the "previous" board
        this.updatedBoardId = this.boardId;
      },
      error() {
        this.apolloError = this.$options.i18n.fetchError;
      },
    },
  },
  computed: {
    ...mapState(['boardLists', 'error', 'addColumnForm']),
    ...mapGetters(['isSwimlanesOn']),
    addColumnFormVisible() {
      return this.addColumnForm?.visible;
    },
    queryVariables() {
      return {
        ...(this.isIssueBoard && {
          isGroup: this.boardType === BoardType.group,
          isProject: this.boardType === BoardType.project,
        }),
        fullPath: this.fullPath,
        boardId: this.boardId,
        filterParams: this.filterParams,
      };
    },
    boardListsToUse() {
      const lists = this.isApolloBoard ? this.boardListsApollo : this.boardLists;
      return sortBy([...Object.values(lists)], 'position');
    },
    canDragColumns() {
      return this.canAdminList;
    },
    boardColumnWrapper() {
      return this.canDragColumns ? Draggable : 'div';
    },
    draggableOptions() {
      const options = {
        ...defaultSortableOptions,
        disabled: this.disabled,
        draggable: '.is-draggable',
        fallbackOnBody: false,
        group: 'boards-list',
        tag: 'div',
        value: this.boardListsToUse,
        delay: 100,
        delayOnTouchOnly: true,
      };

      return this.canDragColumns ? options : {};
    },
    errorToDisplay() {
      return this.isApolloBoard ? this.apolloError : this.error;
    },
  },
  mounted() {
    this.setBoardHeight();

    this.resizeObserver = new ResizeObserver(
      throttle(() => {
        this.setBoardHeight();
      }, 150),
    );
    this.resizeObserver.observe(document.body);
  },
  unmounted() {
    this.resizeObserver.disconnect();
  },
  methods: {
    ...mapActions(['moveList', 'unsetError']),
    afterFormEnters() {
      const el = this.canDragColumns ? this.$refs.list.$el : this.$refs.list;
      el.scrollTo({ left: el.scrollWidth, behavior: 'smooth' });
    },
    setBoardHeight() {
      if (window.innerWidth < breakpoints.md) {
        this.boardHeight = `${window.innerHeight - contentTop()}px`;
      } else {
        this.boardHeight = `${window.innerHeight - this.$el.getBoundingClientRect().top}px`;
      }
    },
  },
};
</script>

<template>
  <div v-cloak data-qa-selector="boards_list">
    <gl-alert v-if="errorToDisplay" variant="danger" :dismissible="true" @dismiss="unsetError">
      {{ errorToDisplay }}
    </gl-alert>
    <component
      :is="boardColumnWrapper"
      v-if="!isSwimlanesOn"
      ref="list"
      v-bind="draggableOptions"
      class="boards-list gl-w-full gl-py-5 gl-pr-3 gl-white-space-nowrap gl-overflow-x-scroll"
      :style="{ height: boardHeight }"
      @end="moveList"
    >
      <board-column
        v-for="(list, index) in boardListsToUse"
        :key="index"
        ref="board"
        :list="list"
        :data-draggable-item-type="$options.draggableItemTypes.list"
        :disabled="disabled"
        :class="{ 'gl-xs-display-none!': addColumnFormVisible }"
      />

      <transition name="slide" @after-enter="afterFormEnters">
        <board-add-new-column v-if="addColumnFormVisible" class="gl-xs-w-full!" />
      </transition>
    </component>

    <epics-swimlanes
      v-else-if="boardListsToUse.length"
      ref="swimlanes"
      :lists="boardListsToUse"
      :can-admin-list="canAdminList"
      :disabled="disabled"
      :style="{ height: boardHeight }"
    />

    <board-content-sidebar v-if="isIssueBoard" data-testid="issue-boards-sidebar" />

    <epic-board-content-sidebar v-else-if="isEpicBoard" data-testid="epic-boards-sidebar" />
  </div>
</template>
