<template>
  <v-container fluid>
    <v-row>
      <v-col cols="12" sm="12">
        <v-sheet min-height="80vh" outlined>
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

          <div class="text-lg-h6">Individuals Table</div>

          <p class="text-justify">
            Search and filter the reviewed individuals in a tabular view.
          </p>

          <!-- User Interface controls -->
          <div class="text-center pt-2">
            <v-row no-gutters>
              <v-col cols="8" class="px-1">
                <v-text-field
                  v-model="filter['any'].content"
                  append-icon="mdi-magnify"
                  label="Search"
                  single-line
                  hide-details
                  dense
                  outlined
                ></v-text-field>
              </v-col>

              <v-col cols="1" class="px-1">
                <v-select
                  v-model="meta.perPage"
                  :items="pageOptions"
                  label="Items per page"
                  dense
                  outlined
                ></v-select>
              </v-col>

              <v-col cols="3" class="px-1">
                <v-pagination
                  v-model="currentPage"
                  :length="meta.totalPages"
                  :total-visible="5"
                  @input="handlePageChange"
                ></v-pagination>
              </v-col>
            </v-row>
          </div>
          <!-- User Interface controls -->

          <div class="pa-2">
            <v-data-table
              dense
              :items="individuals"
              :headers="headers"
              :single-expand="singleExpand"
              :expanded.sync="expanded"
              show-expand
              :items-per-page="meta.perPage"
              :server-items-length="meta.totalItems"
              hide-default-footer
              class="elevation-1"
              item-key="individual_id"
            >
              <template v-slot:expanded-item="{ headers, item }">
                <td :colspan="headers.length">
                  <v-data-table
                    dense
                    :items="item.reports"
                    item-key="report_id"
                    :headers="headers_reports"
                    class="elevation-1"
                    hide-default-footer
                    disable-pagination
                    disable-filtering
                  >
                    <template v-slot:[`item.report_id`]="{ item }">
                      <v-chip
                        color="deep-orange lighten-2"
                        class="ma-2"
                        small
                      >
                        rep{{ item.report_id }}
                        <v-icon right> mdi-newspaper-variant </v-icon>
                      </v-chip>
                    </template>

                    <template v-slot:[`item.cohort`]="{ item }">
                      <v-chip
                        :color="cohort_color[item.cohort]"
                        class="ma-2"
                        small
                      >
                        {{ item.cohort }}
                      </v-chip>
                    </template>

                    <template v-slot:[`item.phenotypes`]="{ item }">
                      <template v-for="phenotype in item.phenotypes">
                        <v-chip
                          class="ma-0"
                          small
                          v-if="phenotype.described === 'yes'"
                          :key="phenotype.phenotype_id"
                          :color="reported_phenotype_color[phenotype.described]"
                        >
                          <v-icon
                          >
                            {{ reported_phenotype_symbol[phenotype.described] }}
                          </v-icon>
                          {{ phenotype.phenotype_name }}
                        </v-chip>
                      </template>
                    </template>
                  </v-data-table>
                </td>
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

              <template v-slot:[`item.sex`]="{ item }">
                <v-icon small>
                  {{ sex_symbol[item.sex] }}
                </v-icon>
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
  name: "TableIndividuals",
  mixins: [urlParsingMixin, colorAndSymbolsMixin],
  data() {
    return {
      individuals: [],
      headers: [
        { text: "Individual", value: "individual_id" },
        { text: "Sex", value: "sex" },
        { text: "DOI", value: "individual_DOI" },
      ],
      headers_reports: [
        { text: "Report", value: "report_id" },
        { text: "Date", value: "report_date" },
        { text: "Cohort", value: "cohort" },
        { text: "Age", value: "report_age" },
        { text: "Onset", value: "onset_age" },
        { text: "Phenotype", value: "phenotypes" },
      ],
      expanded: [],
      singleExpand: true,
      absolute: true,
      opacity: 1,
      color: "#FFFFFF",
      loading: true,
      meta: {
        perPage: 10,
        currentPage: 1,
        totalPages: 1,
        prevItemID: null,
        currentItemID: 0,
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
  mounted() {
    this.loadDataFromAPI();
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

      const apiUrl =
        process.env.VUE_APP_API_URL + "/api/individuals?" + urlParam;

      try {
        let response = await this.axios.get(apiUrl);
        this.individuals = response.data.data;
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