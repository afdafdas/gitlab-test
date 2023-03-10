<script>
import { GlAlert, GlBanner, GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { createAlert, VARIANT_INFO } from '~/flash';
import { getCookie, historyReplaceState, parseBoolean, setCookie } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { SHOW_DELETE_SUCCESS_ALERT } from '~/packages_and_registries/shared/constants';
import {
  PROJECT_RESOURCE_TYPE,
  GROUP_RESOURCE_TYPE,
  GRAPHQL_PAGE_SIZE,
  HIDE_PACKAGE_MIGRATION_SURVEY_COOKIE,
  DELETE_PACKAGE_SUCCESS_MESSAGE,
  DELETE_PACKAGES_ERROR_MESSAGE,
  DELETE_PACKAGES_SUCCESS_MESSAGE,
  EMPTY_LIST_HELP_URL,
  PACKAGE_HELP_URL,
  SURVEY_LINK,
} from '~/packages_and_registries/package_registry/constants';
import getPackagesQuery from '~/packages_and_registries/package_registry/graphql/queries/get_packages.query.graphql';
import destroyPackagesMutation from '~/packages_and_registries/package_registry/graphql/mutations/destroy_packages.mutation.graphql';
import DeletePackage from '~/packages_and_registries/package_registry/components/functional/delete_package.vue';
import PackageTitle from '~/packages_and_registries/package_registry/components/list/package_title.vue';
import PackageSearch from '~/packages_and_registries/package_registry/components/list/package_search.vue';
import PackageList from '~/packages_and_registries/package_registry/components/list/packages_list.vue';
import DeleteModal from '~/packages_and_registries/package_registry/components/delete_modal.vue';

export default {
  components: {
    GlAlert,
    GlBanner,
    GlEmptyState,
    GlLink,
    GlSprintf,
    PackageList,
    PackageTitle,
    PackageSearch,
    DeleteModal,
    DeletePackage,
  },
  inject: ['emptyListIllustration', 'isGroupPage', 'fullPath'],
  data() {
    return {
      alertVariables: null,
      itemsToBeDeleted: [],
      packages: {},
      sort: '',
      filters: {},
      mutationLoading: false,
      showSurveyBanner: !parseBoolean(getCookie(HIDE_PACKAGE_MIGRATION_SURVEY_COOKIE)),
    };
  },
  apollo: {
    packages: {
      query: getPackagesQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data[this.graphqlResource].packages;
      },
      skip() {
        return !this.sort;
      },
    },
  },
  computed: {
    queryVariables() {
      return {
        isGroupPage: this.isGroupPage,
        fullPath: this.fullPath,
        sort: this.isGroupPage ? undefined : this.sort,
        groupSort: this.isGroupPage ? this.sort : undefined,
        packageName: this.filters?.packageName,
        packageType: this.filters?.packageType,
        first: GRAPHQL_PAGE_SIZE,
      };
    },
    graphqlResource() {
      return this.isGroupPage ? GROUP_RESOURCE_TYPE : PROJECT_RESOURCE_TYPE;
    },
    pageInfo() {
      return this.packages?.pageInfo ?? {};
    },
    packagesCount() {
      return this.packages?.count;
    },
    hasFilters() {
      return this.filters.packageName && this.filters.packageType;
    },
    emptySearch() {
      return !this.filters.packageName && !this.filters.packageType;
    },
    emptyStateTitle() {
      return this.emptySearch
        ? this.$options.i18n.emptyPageTitle
        : this.$options.i18n.noResultsTitle;
    },
    isLoading() {
      return this.$apollo.queries.packages.loading || this.mutationLoading;
    },
    refetchQueriesData() {
      return [
        {
          query: getPackagesQuery,
          variables: this.queryVariables,
        },
      ];
    },
  },
  mounted() {
    this.checkDeleteAlert();
  },
  methods: {
    checkDeleteAlert() {
      const urlParams = new URLSearchParams(window.location.search);
      const showAlert = urlParams.get(SHOW_DELETE_SUCCESS_ALERT);
      if (showAlert) {
        // to be refactored to use gl-alert
        createAlert({ message: DELETE_PACKAGE_SUCCESS_MESSAGE, variant: VARIANT_INFO });
        const cleanUrl = window.location.href.split('?')[0];
        historyReplaceState(cleanUrl);
      }
    },
    async confirmDelete() {
      const { itemsToBeDeleted } = this;
      this.itemsToBeDeleted = [];
      this.mutationLoading = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: destroyPackagesMutation,
          variables: {
            ids: itemsToBeDeleted.map((i) => i.id),
          },
          awaitRefetchQueries: true,
          refetchQueries: [
            {
              query: getPackagesQuery,
              variables: { ...this.queryVariables, first: GRAPHQL_PAGE_SIZE },
            },
          ],
        });

        if (data?.destroyPackages?.errors[0]) {
          throw new Error(data.destroyPackages.errors[0]);
        }
        this.showAlert({
          variant: 'success',
          message: DELETE_PACKAGES_SUCCESS_MESSAGE,
        });
      } catch {
        this.showAlert({
          variant: 'danger',
          message: DELETE_PACKAGES_ERROR_MESSAGE,
        });
      } finally {
        this.mutationLoading = false;
      }
    },
    showDeletePackagesModal(toBeDeleted) {
      this.itemsToBeDeleted = toBeDeleted;
      this.$refs.deletePackagesModal.show();
    },
    handleSearchUpdate({ sort, filters }) {
      this.sort = sort;
      this.filters = { ...filters };
    },
    hideSurvey() {
      this.showSurveyBanner = false;
      setCookie(HIDE_PACKAGE_MIGRATION_SURVEY_COOKIE, 'true');
    },
    updateQuery(_, { fetchMoreResult }) {
      return fetchMoreResult;
    },
    fetchNextPage() {
      const variables = {
        ...this.queryVariables,
        first: GRAPHQL_PAGE_SIZE,
        last: null,
        after: this.pageInfo?.endCursor,
      };

      this.$apollo.queries.packages.fetchMore({
        variables,
        updateQuery: this.updateQuery,
      });
    },
    fetchPreviousPage() {
      const variables = {
        ...this.queryVariables,
        first: null,
        last: GRAPHQL_PAGE_SIZE,
        before: this.pageInfo?.startCursor,
      };

      this.$apollo.queries.packages.fetchMore({
        variables,
        updateQuery: this.updateQuery,
      });
    },
    showAlert(obj) {
      this.alertVariables = { ...obj };
    },
  },
  i18n: {
    widenFilters: s__('PackageRegistry|To widen your search, change or remove the filters above.'),
    emptyPageTitle: s__('PackageRegistry|There are no packages yet'),
    noResultsTitle: s__('PackageRegistry|Sorry, your filter produced no results'),
    noResultsText: s__(
      'PackageRegistry|Learn how to %{noPackagesLinkStart}publish and share your packages%{noPackagesLinkEnd} with GitLab.',
    ),
    surveyBannerTitle: s__('PackageRegistry|Help us learn about your registry migration needs'),
    surveyBannerDescription: s__(
      'PackageRegistry|If you are interested in migrating packages from your private registry to the GitLab Package Registry, take our survey and tell us more about your needs.',
    ),
    surveyBannerPrimaryButtonText: s__('PackageRegistry|Take survey'),
  },
  links: {
    EMPTY_LIST_HELP_URL,
    PACKAGE_HELP_URL,
  },
  surveyLink: SURVEY_LINK,
};
</script>

<template>
  <div>
    <gl-alert
      v-if="alertVariables"
      :variant="alertVariables.variant"
      class="gl-mt-5"
      dismissible
      @dismiss="alertVariables = null"
    >
      {{ alertVariables.message }}
    </gl-alert>
    <gl-banner
      v-if="showSurveyBanner"
      :title="$options.i18n.surveyBannerTitle"
      :button-text="$options.i18n.surveyBannerPrimaryButtonText"
      :button-link="$options.surveyLink"
      class="gl-mt-3"
      @primary="hideSurvey"
      @close="hideSurvey"
    >
      <p>{{ $options.i18n.surveyBannerDescription }}</p>
    </gl-banner>
    <package-title :help-url="$options.links.PACKAGE_HELP_URL" :count="packagesCount" />
    <package-search class="gl-mb-5" @update="handleSearchUpdate" />

    <delete-package
      :refetch-queries="refetchQueriesData"
      show-success-alert
      @start="mutationLoading = true"
      @end="mutationLoading = false"
    >
      <template #default="{ deletePackage }">
        <package-list
          :list="packages.nodes"
          :is-loading="isLoading"
          :page-info="pageInfo"
          @prev-page="fetchPreviousPage"
          @next-page="fetchNextPage"
          @package:delete="deletePackage"
          @delete="showDeletePackagesModal"
        >
          <template #empty-state>
            <gl-empty-state :title="emptyStateTitle" :svg-path="emptyListIllustration">
              <template #description>
                <gl-sprintf v-if="hasFilters" :message="$options.i18n.widenFilters" />
                <gl-sprintf v-else :message="$options.i18n.noResultsText">
                  <template #noPackagesLink="{ content }">
                    <gl-link :href="$options.links.EMPTY_LIST_HELP_URL" target="_blank">{{
                      content
                    }}</gl-link>
                  </template>
                </gl-sprintf>
              </template>
            </gl-empty-state>
          </template>
        </package-list>
      </template>
    </delete-package>

    <delete-modal
      ref="deletePackagesModal"
      :items-to-be-deleted="itemsToBeDeleted"
      @confirm="confirmDelete"
    />
  </div>
</template>
