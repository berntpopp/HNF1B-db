<template>
  <v-container>
    <v-row>
      <v-col cols="12" sm="12">
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

        <v-card color="white" class="my-2">
          <v-card-title class="text-h5 blue lighten-2">
            Welcome to HNF1B-db
          </v-card-title>
          <v-card-text>
            <!--// database statistics //-->
            The database currently contains

            <v-chip
              color="lime lighten-2"
              class="ma-2"
              small
              link
              to="/table_individuals"
            >
              <span class="font-weight-bold"
                >{{ statistics.individuals_count }} individuals</span
              >
              <v-icon right> {{ icons.mdiAccount }} </v-icon>
            </v-chip>

            with

            <v-chip
              color="pink lighten-4"
              class="ma-2"
              small
              link
              to="/table_variants"
            >
              <span class="font-weight-bold">
                {{ statistics.variants_count }} distinct variants</span
              >
              <v-icon right> {{ icons.mdiDna }} </v-icon>
            </v-chip>

            from

            <v-chip
              color="deep-orange lighten-2"
              class="ma-2"
              small
              link
              to="/table_reports"
            >
              <span class="font-weight-bold">
                {{ statistics.reports_count }} reports</span
              >
              <v-icon right> {{ icons.mdiNewspaperVariant }} </v-icon>
            </v-chip>

            in

            <v-chip
              color="cyan accent-2"
              class="ma-2"
              small
              link
              to="/table_publications"
            >
              <span class="font-weight-bold">
                {{ statistics.publications_count }} reviewed publications</span
              >
              <v-icon right> {{ icons.mdiBookOpenBlankVariant }} </v-icon>
            </v-chip>
            <!--// database statistics //-->
          </v-card-text>

          <v-card-text>
            <v-autocomplete
              color="black"
              hide-no-data
              hide-selected
              item-text="Description"
              item-value="API"
              label="Individuals, reports, publications and variants"
              placeholder="Start typing to Search"
              :prepend-icon="icons.mdiDatabase"
              :append-icon="icons.mdiMagnify"
              return-object
              :items="search_keys"
              :loading="searchLoading"
              :search-input.sync="search_input"
              @click:append="keydown_handler"
              @keydown.native="keydown_handler"
            ></v-autocomplete>
          </v-card-text>
          <v-divider></v-divider>
          <v-expand-transition> </v-expand-transition>
        </v-card>

        <v-card color="white" class="my-2">
          <v-card-title class="text-h5 blue lighten-2">
            Small HNF1B variants
          </v-card-title>

          <v-card-text class="d-flex justify-center">
            <ProteinLinearPlot :show_controls="true"></ProteinLinearPlot>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
import ProteinLinearPlot from "@/components/analyses/ProteinLinearPlot.vue";
import { mdiAccount, mdiDna, mdiNewspaperVariant, mdiBookOpenBlankVariant, mdiDatabase, mdiMagnify } from '@mdi/js';

export default {
  name: "Home",
  components: {
    ProteinLinearPlot,
  },
  data() {
    return {
      icons: {
        mdiAccount,
        mdiDna,
        mdiNewspaperVariant,
        mdiBookOpenBlankVariant,
        mdiDatabase,
        mdiMagnify,
      },
      statistics: {
        reports_count: 0,
        publications_count: 0,
        individuals_count: 0,
        variants_count: 0,
      },
      absolute: true,
      opacity: 1,
      color: "#FFFFFF",
      image_publications: "",
      image_cohort: "",
      image_phenotype: "",
      search_input: null,
      search_keys: [],
      search_object: {},
      searchLoading: false,
      loading: true,
    };
  },
  computed: {},
  watch: {
  search_input () {
    if (this.search_input) {
      this.loadSearchInfo();
    }
  },
},
  mounted() {
    this.loadStatisticsData();
  },
  methods: {
    async loadStatisticsData() {
      this.loading = true;
      let apiUrl =
        process.env.VUE_APP_API_URL + "/api/statistics/database_statistics";
      try {
        let response = await this.axios.get(apiUrl);

        this.statistics.reports_count = response.data.filter((obj) => {
          return obj.value === "reports";
        })[0].count;
        this.statistics.publications_count = response.data.filter((obj) => {
          return obj.value === "publications";
        })[0].count;
        this.statistics.individuals_count = response.data.filter((obj) => {
          return obj.value === "individuals";
        })[0].count;
        this.statistics.variants_count = response.data.filter((obj) => {
          return obj.value === "variants";
        })[0].count;
      } catch (e) {
        console.error(e);
      }
      this.loading = false;
    },
    async loadSearchInfo() {
      this.searchLoading = true;

        const apiSearchURL = `${process.env.VUE_APP_API_URL
        }/api/search/${
          this.search_input
        }?helper=true`;
        try {
          const response_search = await this.axios.get(apiSearchURL);
          let rest;
          [this.search_object, ...rest] = response_search.data;
          this.search_keys = Object.keys(response_search.data[0]);
        } catch (e) {
          console.error(e);
        }

      this.searchLoading = false;

    },
    keydown_handler(event) {
      if (
        ((event.which === 13) || (event.which === 1))
        && (this.search_input)
        && !(this.search_object[this.search_input] === undefined)
      ) {
        this.$router.push(this.search_object[this.search_input][0].link);
        this.search_input = '';
        this.search_keys = [];
      } else if (
        ((event.which === 13) || (event.which === 1))
        && (this.search_input)
        && (this.search_object[this.search_input] === undefined)
      ) {
        this.$router.push(`/search?term=${this.search_input}`);
        this.search_input = '';
        this.search_keys = [];
      }
    },
  },
};
</script>
