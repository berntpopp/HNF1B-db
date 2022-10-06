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
              :items="variants"
              :headers="headers"
              :items-per-page="meta.perPage"
              :server-items-length="meta.totalItems"
              hide-default-footer
              class="elevation-1"
              item-key="name"
            >
              <template v-slot:[`item.variant_id`]="{ item }">
                <v-chip
                  color="pink lighten-4"
                  class="ma-2"
                  small
                  link
                  :to="'/variant/' + item.variant_id"
                >
                  var{{ item.variant_id }}
                  <v-icon right> {{ icons.mdiDna }} </v-icon>
                </v-chip>
              </template>

              <template v-slot:[`item.variant_class`]="{ item }">
                <v-chip
                  class="ma-1"
                  small
                  :color="variant_class_color[item.variant_class]"
                >
                  {{ item.variant_class }}
                </v-chip>
              </template>

              <template v-slot:[`item.verdict_classification`]="{ item }">
                <v-tooltip top>
                <template v-slot:activator="{ on, attrs }">
                  <v-chip
                    small
                    class="ma-1"
                    v-bind="attrs"
                    v-on="on"
                    :color="classification_color[item.verdict_classification]"
                  >
                    {{ item.verdict_classification }}
                  </v-chip>
                </template>
                <span>{{ item.criteria_classification.join(", ") }}</span>
                </v-tooltip>
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
  name: "TableVariants",
  mixins: [urlParsingMixin, colorAndSymbolsMixin],
  props: {
    showFilterControls: { type: Boolean, default: true },
    showPaginationControls: { type: Boolean, default: true },
    headerLabel: { type: String, default: "Variants Table" },
    headerSubLabel: {
      type: String,
      default: "Search and filter the reviewed variants in a tabular view.",
    },
    sortInput: { type: String, default: "+variant_id" },
    filterInput: { type: String, default: "filter=" },
    fieldsInput: { type: String, default: null },
    pageAfterInput: { type: Number, default: 0 },
    pageSizeInput: { type: Number, default: 10 },
  },
  data() {
    return {
      variants: [],
      headers: [
        { text: "Variant", value: "variant_id" },
        { text: "Type", value: "variant_class" },
        { text: "VCF [hg19]", value: "vcf_hg19" },
        { text: "Transcript", value: "HGVS_C" },
        { text: "Protein", value: "HGVS_P" },
        { text: "Classification", value: "verdict_classification" },
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

      const apiUrl = process.env.VUE_APP_API_URL + "/api/variants?" + urlParam;

      try {
        let response = await this.axios.get(apiUrl);
        this.variants = response.data.data;
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