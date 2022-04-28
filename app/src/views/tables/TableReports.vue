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
            Reports Table
            </div>
  
            <p class="text-justify">
              Search and filter the reviewed reports in a tabular view.
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
                  :items="reports"
                  :headers="headers"
                  :search="search"
                  item-key="name"
                  class="elevation-1"
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
                
                <template v-slot:[`item.reported_multiple`]="{ item }">
                  <v-icon
                    small
                  >
                    {{ logical_symbol[item.reported_multiple] }}
                  </v-icon>
                </template>

                <template v-slot:[`item.sex_reported`]="{ item }">
                  <v-icon
                    small
                  >
                    {{ sex_symbol[item.sex_reported] }}
                  </v-icon>
                </template>

                <template v-slot:[`item.cohort`]="{ item }">
                  <v-chip
                    :color="cohort_style[item.cohort]"
                    class="ma-2"
                    x-small
                  >
                    {{ item.cohort }}
                  </v-chip>
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
  name: 'TableReports',
  data() {
        return {
          cohort_style: {"born": "success", "fetus": "primary"},
          sex_symbol: {"female": "mdi-gender-female", "male": "mdi-gender-male", "unspecified": "mdi-help-circle-outline"},
          logical_symbol: {"1": "mdi-check-circle-outline", "0": "mdi-minus-circle-outline"},
          reports: [],
          headers:[
            { text:'Report', value: 'report_id' },
            { text:"Individual", value:"individual_id" },
            { text:"Reported multiple", value:"reported_multiple" },
            { text:"Sex", value:"sex_reported" },
            { text:"Cohort", value:"cohort" },
            { text:"Age onset", value:"onset_age" },
            { text:"Age report", value:"report_age" }
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
        this.loadReportsData();
      },
      methods: {
        async loadReportsData() {
          this.loading = true;
          let apiUrl = process.env.VUE_APP_API_URL + '/api/reports';
          try {
            let response = await this.axios.get(apiUrl);
            this.reports = response.data.data;
            this.totalRows = response.data.data.length;
          } catch (e) {
            console.error(e);
          }
          this.loading = false;
        }
      }
  }
</script>