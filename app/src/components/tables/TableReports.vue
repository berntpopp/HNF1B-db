<template>
  <v-container fluid>
    <v-row>
      <v-col cols="12" sm="12">
        <v-sheet outlined>
          <v-overlay
            :absolute="absolute"
            :opacity="opacity"
            :value="loading"
            :color="color"
          >
            <v-progress-circular
              indeterminate
              color="primary"
            ></v-progress-circular>
          </v-overlay>

          <div class="text-lg-h6">
            {{ headerLabel }}
          </div>

          <p class="text-justify">
            {{ headerSubLabel }}
          </p>

          <!-- User Interface controls -->
          <div class="text-center pt-2">
            <v-row no-gutters>
              <v-col cols="8" class="px-1">
                <v-container
                  v-if="showFilterControls"
                >
                  <v-text-field
                    v-model="filter['any'].content"
                    append-icon="mdi-magnify"
                    label="Search"
                    single-line
                    hide-details
                    dense
                    outlined
                  >
                  </v-text-field>
                </v-container>
              </v-col>

              <v-col cols="1" class="px-1">
                <v-container
                  v-if="meta.totalItems > meta.perPage || showPaginationControls"
                >
                  <v-select
                    v-model="meta.perPage"
                    :items="pageOptions"
                    label="Items per page"
                    dense
                    outlined
                  ></v-select>
                </v-container>
              </v-col>

              <v-col cols="3" class="px-1">
                <v-container
                  v-if="meta.totalItems > meta.perPage || showPaginationControls"
                >
                  <v-pagination
                    v-model="currentPage"
                    :length="meta.totalPages"
                    :total-visible="5"
                    @input="handlePageChange"
                  ></v-pagination>
                </v-container>
              </v-col>
            </v-row>
          </div>
          <!-- User Interface controls -->

          <div class="pa-2">
            <v-data-table
              dense
              :items="reports"
              :headers="headers"
              :items-per-page="meta.perPage"
              :server-items-length="meta.totalItems"
              hide-default-footer
              class="elevation-1"
              item-key="name"
            >
              <template v-slot:[`item.report_id`]="{ item }">
                <v-chip
                  color="deep-orange lighten-2"
                  class="ma-2"
                  small
                  link
                  :to="'/report/' + item.report_id"
                >
                  rep{{ item.report_id }}
                  <v-icon right> mdi-newspaper-variant </v-icon>
                </v-chip>
              </template>

              <template v-slot:[`item.individual_id`]="{ item }">
                <v-chip
                  color="lime lighten-2"
                  class="ma-2"
                  small
                  link
                  :to="'/individual/' + item.individual_id"
                >
                  ind{{ item.individual_id }}
                  <v-icon right> mdi-account </v-icon>
                </v-chip>
              </template>

              <template v-slot:[`item.reported_multiple`]="{ item }">
                <v-icon small>
                  {{ logical_symbol[item.reported_multiple] }}
                </v-icon>
              </template>

              <template v-slot:[`item.sex_reported`]="{ item }">
                <v-icon small>
                  {{ sex_symbol[item.sex_reported] }}
                </v-icon>
              </template>

              <template v-slot:[`item.cohort`]="{ item }">
                <v-chip
                  :color="cohort_style[item.cohort]"
                  class="ma-2"
                  small
                >
                  {{ item.cohort }}
                </v-chip>
              </template>
            </v-data-table>
          </div>
        </v-sheet>
      </v-col>
    </v-row>
  </v-container>
</template>


<script>
import urlParsingMixin from "@/assets/js/mixins/urlParsingMixin.js";
import colorAndSymbolsMixin from "@/assets/js/mixins/colorAndSymbolsMixin.js";

export default {
  name: "TableReports",
  mixins: [urlParsingMixin, colorAndSymbolsMixin],
  props: {
    showFilterControls: { type: Boolean, default: true },
    showPaginationControls: { type: Boolean, default: true },
    headerLabel: { type: String, default: "Reports Table<" },
    headerSubLabel: { type: String, default: "Search and filter the reviewed reports in a tabular view." },
    sortInput: { type: String, default: "+report_id" },
    filterInput: { type: String, default: "filter=" },
    fieldsInput: { type: String, default: null },
    pageAfterInput: { type: Number, default: 0 },
    pageSizeInput: { type: Number, default: 10 },
  },
  data() {
    return {
      reports: [],
      headers: [
        { text: "Report", value: "report_id" },
        { text: "Individual", value: "individual_id" },
        { text: "Reported multiple", value: "reported_multiple" },
        { text: "Sex", value: "sex_reported" },
        { text: "Cohort", value: "cohort" },
        { text: "Age onset", value: "onset_age" },
        { text: "Age report", value: "report_age" },
      ],
      absolute: true,
      opacity: 1,
      color: "#FFFFFF",
      loading: true,
      meta: {
        perPage: this.pageSizeInput,
        currentPage: 1,
        totalPages: 1,
        prevItemID: null,
        currentItemID: this.pageAfterInput,
        nextItemID: null,
        lastItemID: null,
        totalItems: 0,
        sort: "",
        fields: "",
        executionTime: "",
      },
      filter: {
        any: { content: null, join_char: null, operator: "contains" },
      },
      filter_string: "",
      currentPage: 0,
      pageOptions: [10, 25, 50, 200],
    };
  },
  computed: {
    perPage() {
      return this.meta.perPage;
    },
  },
  watch: {
    filter: {
      handler() {
        this.filtered();
      },
      deep: true,
    },
    perPage: {
      handler() {
        this.meta.currentItemID = 0;
        this.handlePerPageChange();
      },
    },
  },
  created() {
    // transform input filter string from params to object and assign
    this.filter = this.filterStrToObj(this.filterInput, this.filter);
  },
  mounted() {
  },
  methods: {
    handlePerPageChange() {
      this.currentItemID = 0;
      this.loadDataFromAPI();
    },
    handlePageChange(value) {
      if (value == 1) {
        this.meta.currentItemID = 0;
        this.loadDataFromAPI();
      } else if (value == this.meta.totalPages) {
        this.meta.currentItemID = this.meta.lastItemID;
        this.loadDataFromAPI();
      } else if (value > this.meta.currentPage) {
        this.meta.currentItemID = this.meta.nextItemID;
        this.loadDataFromAPI();
      } else if (value < this.meta.currentPage) {
        this.meta.currentItemID = this.meta.prevItemID;
        this.loadDataFromAPI();
      }
    },
    filtered() {
      // simulatte debounce behaviour
      // based on https://stackoverflow.com/questions/42133894/vue-js-how-to-properly-watch-for-nested-data
      // cancel pending call
      clearTimeout(this._timerId);
      // delay new call 500ms
      this._timerId = setTimeout(() => {
        this.filter_string = this.filterObjToStr(this.filter);
        this.loadDataFromAPI();
      }, 500);
    },
    async loadDataFromAPI() {
      this.loading = true;

      const urlParam =
        "&filter=" +
        this.filter_string +
        "&page_after=" +
        this.meta.currentItemID +
        "&page_size=" +
        this.meta.perPage;

      const apiUrl = process.env.VUE_APP_API_URL + "/api/reports?" + urlParam;

      try {
        let response = await this.axios.get(apiUrl);
        this.reports = response.data.data;
        this.meta = response.data.meta[0];
        this.currentPage = response.data.meta[0].currentPage;
      } catch (e) {
        console.error(e);
      }
      this.loading = false;
    },
  },
};
</script>