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

          <div class="text-lg-h6">Publications Table</div>

          <p class="text-justify">
            Search and filter the reviewed publications in a tabular view.
          </p>

          <!-- User Interface controls -->
          <div class="text-center pt-2">
            <v-row no-gutters>
              <v-col cols="8" class="px-1">
                <v-container v-if="showFilterControls">
                  <v-text-field
                    v-model="filter['any'].content"
                    :append-icon="icons.mdiMagnify"
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
                  v-if="
                    meta.totalItems > meta.perPage || showPaginationControls
                  "
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
                  v-if="
                    meta.totalItems > meta.perPage || showPaginationControls
                  "
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
              :items="publications"
              :headers="headers"
              :items-per-page="meta.perPage"
              :server-items-length="meta.totalItems"
              hide-default-footer
              class="elevation-1"
              item-key="name"
            >
              <template v-slot:[`item.publication_id`]="{ item }">
                <v-chip
                  color="cyan accent-2"
                  class="ma-2"
                  small
                  link
                  :to="'/publication/' + item.publication_id"
                >
                  pub{{ item.publication_id }}
                  <v-icon right> {{ icons.mdiBookOpenBlankVariant }} </v-icon>
                </v-chip>
              </template>

              <template v-slot:[`item.PMID`]="{ item }">
                <a
                  :href="'https://pubmed.ncbi.nlm.nih.gov/' + item.PMID"
                  aria-label="Link out to PubMed"
                  target="_blank"
                >
                  {{ item.PMID }}
                </a>
              </template>

              <template v-slot:[`item.DOI`]="{ item }">
                <a
                  :href="'https://doi.org/' + item.DOI"
                  aria-label="Link out to Digital Object Identifier (DOI) System"
                  target="_blank"
                >
                  {{ item.DOI }}
                </a>
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
  name: "TablePublications",
  mixins: [urlParsingMixin, colorAndSymbolsMixin],
  props: {
    showFilterControls: { type: Boolean, default: true },
    showPaginationControls: { type: Boolean, default: true },
    headerLabel: { type: String, default: "Publications Table" },
    headerSubLabel: {
      type: String,
      default: "Search and filter the reviewed publications in a tabular view.",
    },
    sortInput: { type: String, default: "+individual_id" },
    filterInput: { type: String, default: "filter=" },
    fieldsInput: { type: String, default: null },
    pageAfterInput: { type: Number, default: 0 },
    pageSizeInput: { type: Number, default: 10 },
  },
  data() {
    return {
      publications: [],
      headers: [
        { text: "Publication", value: "publication_id" },
        { text: "Type", value: "publication_type" },
        { text: "PMID", value: "PMID" },
        { text: "DOI", value: "DOI" },
        { text: "First Author", value: "firstauthor_lastname" },
        { text: "Journal", value: "journal" },
        { text: "Date", value: "publication_date" },
      ],
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
  created() {
    // transform input filter string from params to object and assign
    this.filter = this.filterStrToObj(this.filterInput, this.filter);
  },
  mounted() {},
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
        process.env.VUE_APP_API_URL + "/api/publications?" + urlParam;

      try {
        let response = await this.axios.get(apiUrl);
        this.publications = response.data.data;
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