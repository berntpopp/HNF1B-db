<template>
       <v-container>
        <v-row>
          <v-col
            cols="12"
            sm="12"
          >

            <v-sheet
              min-height="70vh"
              outlined
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

<!-- Tabs section -->
            <v-tabs
              v-model="tab"
              background-color="transparent"
              color="basil"
              grow
            >
              <v-tab
                v-for="item in items"
                :key="item"
              >
                {{ item }}
              </v-tab>
            </v-tabs>

            <v-tabs-items v-model="tab">

              <v-tab-item
                key="Publications over time"
              >
                <v-container fill-height>
                    <v-row justify="center" align="center">
                        <v-col cols="12" sm="4">

                          <v-img
                            :src="image_publications"
                          ></v-img>

                        </v-col>
                    </v-row>
                </v-container>
              </v-tab-item>

              <v-tab-item
                key="Cohort characteristic"
              >
                <v-container fill-height>
                    <v-row justify="center" align="center">
                        <v-col cols="12" sm="4">

                          <v-img
                            :src="image_cohort"
                          ></v-img>

                        </v-col>
                    </v-row>
                </v-container>
              </v-tab-item>

              <v-tab-item
                key="Phenotypes reported"
              >
                <v-container fill-height>
                    <v-row justify="center" align="center">
                        <v-col cols="12" sm="4">

                            <v-img
                              :src="image_phenotype"
                            ></v-img>

                        </v-col>
                    </v-row>
                </v-container>
              </v-tab-item>
          
            </v-tabs-items>
<!-- Tabs section -->

            </v-sheet>
          </v-col>
        </v-row>
        
      </v-container>
</template>

<script>

  export default {
    name: 'Cohort characteristics',
  data() {
        return {
          tab: null,
          items: [ 'Publications over time', 'Cohort characteristic', 'Phenotypes reported' ],
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
        this.loadImages();
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
        async loadImages() {
          this.loading = true;
          let apiPublicationsPlot = process.env.VUE_APP_API_URL + '/api/statistics/publications_plot';
          let apiCohortPlot = process.env.VUE_APP_API_URL + '/api/statistics/cohort_plot';
          let apiPhenotypePlot = process.env.VUE_APP_API_URL + '/api/statistics/phenotype_plot';

          try {
            let response_publications_plot = await this.axios.get(apiPublicationsPlot);
            let response_cohort_plot = await this.axios.get(apiCohortPlot);
            let response_phenotype_plot = await this.axios.get(apiPhenotypePlot);

            this.image_publications = 'data:image/png;base64,'.concat(this.image_publications.concat(response_publications_plot.data));
            this.image_cohort = 'data:image/png;base64,'.concat(this.image_cohort.concat(response_cohort_plot.data));
            this.image_phenotype = 'data:image/png;base64,'.concat(this.image_phenotype.concat(response_phenotype_plot.data));
            } catch (e) {
            console.error(e);
            }
          this.loading = false;
        }
      }

  }
</script>
