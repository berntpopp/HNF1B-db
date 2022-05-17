<template>
    <v-img
    :src="image_cohort"
    ></v-img>
</template>


<script>

  export default {
    name: 'CohortPlot',
  data() {
        return {
          image_publications: '',
          image_cohort: '',
          image_phenotype: '',
        }
      },
      computed: {
      },
      mounted() {
        this.loadImages();
      },
      methods: {
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
        },
    }

  }
</script>