<template>
       <v-container>
        <v-row>
          <v-col
            cols="12"
            sm="12"
          >

            <v-sheet
              min-height="70vh"
              rounded="lg"
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

              <div class="text-lg-h6 pa-2">
                HNF1b-db
              </div>
              <div class="text-justify pa-2">
                Pathogenic variants in the <span class="font-italic">HNF1B</span>-gene are associated with a variety of inherited kidney diseases ranging from renal cysts and diabetes syndrome (RCAD) and CAKUT to autosomal dominant tubulointerstitial kidney disease (ADTKD). In addition, variable extrarenal manifestations, such as abnormalities of the genital tract (vaginal aplasia, uterus malformation), gout, pancreatic insufficiency, electrolyte abnormalities, liver disease, neurodevelopmental and neuropsychological disorders have been linked to <span class="font-italic">HNF1B </span>-defects (MIM #189907).
              </div>
              <div class="text-justify pa-2">
                To standardize the clinical and genetic spectrum, we curated a list of 30 clinical features associated with <span class="font-italic">HNF1B </span>-disease based on HPO-terms. We then developed a HNF1B-db as web-based application and database to store and share this data.The HNF1b-db currently contains <span class="font-weight-bold"> {{ statistics.individuals_count }} individuals </span> 
                with <span class="font-weight-bold"> {{ statistics.variants_count }} distinct variants </span>
                from <span class="font-weight-bold"> {{ statistics.reports_count }} reports </span> in
                <span class="font-weight-bold"> {{ statistics.publications_count }} reviewed publications </span>.
                <br><br>
              </div>

              <!--// cards with image summaries //-->
              <v-row>
                <v-col>
                  
                  <v-card
                    class="mx-auto"
                    max-width="320"
                    height="100%"
                  >
                    <v-img
                      :src="image_publications"
                    ></v-img>
                    <v-card-title>
                      Publications over time
                    </v-card-title>
                    <v-card-subtitle>
                      Plot showing the published publications by type since first description.
                    </v-card-subtitle>
                  </v-card>

                </v-col>
                <v-col>

                  <v-card
                    class="mx-auto"
                    max-width="320"
                    height="100%"
                  >
                    <v-img
                      :src="image_cohort"
                    ></v-img>
                    <v-card-title>
                      Cohort characteristic
                    </v-card-title>
                    <v-card-subtitle>
                      Plot showing the distribution of individual sex, fraction of prenatal cases and fraction of repeatedly reported individuals.
                    </v-card-subtitle>
                  </v-card>

                </v-col>

                <v-col>

                  <v-card
                    class="mx-auto"
                    max-width="320"
                    height="100%"
                  >
                    <v-img
                      :src="image_phenotype"
                    ></v-img>
                    <v-card-title>
                      Phenotypes reported most
                    </v-card-title>
                    <v-card-subtitle>
                      Plot showing phenotypes described in over 15% of individuals.
                    </v-card-subtitle>
                  </v-card>

                </v-col>
              </v-row>

            </v-sheet>
          </v-col>

        </v-row>
        
      </v-container>
</template>

<script>

  export default {
    name: 'Home',
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
