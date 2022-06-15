<template>
       <v-container fluid>
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
                  :single-expand="singleExpand"
                  :expanded.sync="expanded"
                  show-expand
                  item-key="individual_id"
                  class="elevation-1"
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
                          x-small
                        >
                          rep{{ item.report_id }}
                          <v-icon right>
                            mdi-newspaper-variant
                          </v-icon>
                        </v-chip>
                      </template>

                      <template v-slot:[`item.cohort`]="{ item }">
                        <v-chip
                          :color="cohort_color[item.cohort]"
                          class="ma-2"
                          x-small
                        >
                          {{ item.cohort }}
                        </v-chip>
                      </template>

                      <template v-slot:[`item.phenotypes`]="{ item }">
                        
                        <template v-for="phenotype in item.phenotypes">
                          <v-chip
                            class="ma-0"
                            x-small
                            v-if="phenotype.described === 'yes'"
                            :key="phenotype.phenotype_id"
                            :color="reported_phenotype_color[phenotype.described]"
                          >
                            <v-icon
                              x-small
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
                    x-small
                    link
                    :to="'/individual/' + item.individual_id"
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
  name: 'TableIndividuals',
  data() {
        return {
          cohort_color: {"born": "success", "fetus": "primary"},
          sex_symbol: {"female": "mdi-gender-female", "male": "mdi-gender-male", "unspecified": "mdi-help-circle-outline"},
          logical_symbol: {"1": "mdi-check-circle-outline", "0": "mdi-minus-circle-outline"},
          reported_phenotype_color: {"yes": "teal lighten-1", "no": "light-blue", "not reported": "white"},
          reported_phenotype_symbol: {"yes": "mdi-plus-circle-outline", "no": "mdi-minus-circle-outline", "not reported": "mdi-help-circle-outline"},
          sex_symbol: {"female": "mdi-gender-female", "male": "mdi-gender-male", "unspecified": "mdi-help-circle-outline"},
          cohort_style: {"born": "success", "fetus": "primary"},
          individuals: [],
          headers:[
            { text:'Individual', value: 'individual_id' },
            { text:"Sex", value:"sex" },
            { text:"DOI", value:"individual_DOI" },
          ],
          headers_reports:[
            { text:'Report', value: 'report_id' },
            { text:'Date', value: 'report_date' },
            { text:"Cohort", value:"cohort" },
            { text:"Age", value:"report_age" },
            { text:"Onset", value:"onset_age" },
            { text:"Phenotype", value:"phenotypes" },
          ],
        expanded: [],
        singleExpand: true,
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
        },
      }
  }
</script>