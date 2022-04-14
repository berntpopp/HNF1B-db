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

            <div 
              class="text-lg-h6"
            >
            Individuals Table
            </div>
  
            <p class="text-justify">
              Search and filter the reviewed individuals in a tabular view.
            </p>

            <div class="pa-2">
                <v-text-field
                  v-model="search"
                  append-icon="mdi-magnify"
                  label="Search"
                  single-line
                  hide-details
                ></v-text-field>

                <v-data-table
                  dense
                  :items="individuals"
                  :headers="headers"
                  :search="search"
                  item-key="name"
                  class="elevation-1"
                >

                <template v-slot:[`item.individual_id`]="{ item }">
                  <v-chip
                    color="lime lighten-2"
                    class="ma-2"
                    x-small
                  >
                    ind{{ item.individual_id }}
                   <v-icon right>
                      mdi-account
                    </v-icon>
                  </v-chip>
                </template>

                <template v-slot:[`item.sex`]="{ item }">
                  <v-icon
                    small
                  >
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
export default {
  name: 'Tables',
  data() {
        return {
          stoplights_style: {"born": "success", "fetus": "primary"},
          sex_symbol: {"female": "mdi-gender-female", "male": "mdi-gender-male", "unspecified": "mdi-help-circle-outline"},
          logical_symbol: {"1": "mdi-check-circle-outline", "0": "mdi-minus-circle-outline"},
          individuals: [],
          headers:[
            { text:'Individual', value: 'individual_id' },
            { text:"Sex", value:"sex" },
            { text:"DOI", value:"individual_DOI" },
          ],
          search: '',
          totalRows: 1,
          absolute: true,
          opacity: 1,
          color: "#FFFFFF",
          loading: true
        }
      },
      computed: {
      },
      mounted() {
        this.loadIndividualsData();
      },
      methods: {
        async loadIndividualsData() {
          this.loading = true;
          let apiUrl = process.env.VUE_APP_API_URL + '/api/individuals';
          try {
            let response = await this.axios.get(apiUrl);
            this.individuals = response.data.data;
            this.totalRows = response.data.data.length;
          } catch (e) {
            console.error(e);
          }
          this.loading = false;
        }
      }
  }
</script>