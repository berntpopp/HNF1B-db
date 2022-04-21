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

            <div 
              class="text-lg-h6"
            >
              <h3>Individual: 
                <v-chip
                  color="lime lighten-2"
                  class="ma-2"
                  small
                >
                  ind{{ $route.params.individual_id }}
                  <v-icon right>
                    mdi-account
                  </v-icon>
                </v-chip>
              </h3>
            </div>
  
            {{ individual }}

            </v-sheet>
          </v-col>

        </v-row>
      </v-container>
</template>


<script>
export default {
  name: 'PageIndividual',
  data() {
        return {
          individual: [],
          absolute: true,
          opacity: 1,
          color: "#FFFFFF",
          loading: true
        }
      },
      computed: {
      },
      mounted() {
        this.loadIndividualData();
      },
      methods: {
        async loadIndividualData() {
          this.loading = true;

          let apiUrl = process.env.VUE_APP_API_URL + '/api/individuals?filter=equals(individual_id,' + this.$route.params.individual_id + ')';

          try {
            let response = await this.axios.get(apiUrl);
            this.individual = response.data.data;
            console.log(this.individual);

          } catch (e) {
            console.error(e);
          }
          this.loading = false;
        }
      }
  }
</script>