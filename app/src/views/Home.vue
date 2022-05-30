<template>
  <v-container>
  <v-row>
    <v-col
      cols="12"
      sm="12"
    >

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

        <v-card
          color="white"
          class="my-2"
        >
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
                <span class="font-weight-bold">{{ statistics.individuals_count }} individuals</span> 
                <v-icon right>
                  mdi-account
                </v-icon>
              </v-chip>

              with 

              <v-chip
                color="pink lighten-4"
                class="ma-2"
                small
                link
                to="/table_variants"
              >
                <span class="font-weight-bold"> {{ statistics.variants_count }} distinct variants</span>
              <v-icon right>
                  mdi-dna
                </v-icon>
              </v-chip>

              from 

              <v-chip
                color="deep-orange lighten-2"
                class="ma-2"
                small
                link
                to="/table_reports"
              >
                <span class="font-weight-bold"> {{ statistics.reports_count }} reports</span>
                <v-icon right>
                  mdi-newspaper-variant
                </v-icon>
              </v-chip>

              in

              <v-chip
                color="cyan accent-2"
                class="ma-2"
                small
                link
                to="/table_publications"
              >
                <span class="font-weight-bold"> {{ statistics.publications_count }} reviewed publications</span>
                <v-icon right>
                  mdi-book-open-blank-variant
                </v-icon>
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
              prepend-icon="mdi-database-search"
              return-object
            ></v-autocomplete>
          </v-card-text>
          <v-divider></v-divider>
          <v-expand-transition>
          </v-expand-transition>
        </v-card>

        <v-card
          color="white"
          class="my-2"
        >
          <v-card-title class="text-h5 blue lighten-2">
            Small HNF1B variants
          </v-card-title>

          <v-card-text
            class="d-flex justify-center"
          >
            <ProteinLinearPlot></ProteinLinearPlot>
          </v-card-text>

        </v-card>

    </v-col>
  </v-row>
</v-container>
</template>

<script>
import ProteinLinearPlot from '@/components/ProteinLinearPlot.vue';

  export default {
    name: 'Home',
    components: {
      ProteinLinearPlot
    },
  data() {
        return {
          statistics: { "reports_count": 0, "publications_count": 0, "individuals_count": 0, "variants_count": 0 },
          absolute: true,
          opacity: 1,
          color: "#FFFFFF",
          image_publications: '',
          image_cohort: '',
          image_phenotype: '',
          loading: true
        }
      },
      computed: {
      },
      mounted() {
        this.loadStatisticsData();
      },
      methods: {
        async loadStatisticsData() {
          this.loading = true;
          let apiUrl = process.env.VUE_APP_API_URL + '/api/statistics';
          try {
            let response = await this.axios.get(apiUrl);

            this.statistics.reports_count = response.data.filter(obj => {return obj.value === "reports"})[0].count;
            this.statistics.publications_count = response.data.filter(obj => {return obj.value === "publications"})[0].count;
            this.statistics.individuals_count = response.data.filter(obj => {return obj.value === "individuals"})[0].count;
            this.statistics.variants_count = response.data.filter(obj => {return obj.value === "variants"})[0].count;

          } catch (e) {
            console.error(e);
          }
          this.loading = false;
        },
      }

  }
</script>
