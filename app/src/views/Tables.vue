<template>
       <v-container>
        <v-row>
          <v-col
            cols="12"
            sm="2"
          >
            <v-sheet
              rounded="lg"
              min-height="70vh"
            >
            <v-list-item
              v-for="item in items_side"
              :key="item.title"
            >
              {{ item.title }}
            </v-list-item>

            </v-sheet>
          </v-col>

          <v-col
            cols="12"
            sm="10"
          >
            <v-sheet
              min-height="70vh"
              rounded="lg"
            >
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
                ></v-data-table>
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
          reports: [],
          headers:[
            { text:'Report', value: 'report_id'  },
            { text:"Individual", value:"individual_id" },
            { text:"Reported multiple", value:"reported_multiple" },
            { text:"Sex", value:"sex_reported" },
            { text:"Cohort", value:"cohort" },
            { text:"Age onset", value:"onset_age" },
            { text:"Age report", value:"report_age" }
          ],
          search: '',
          totalRows: 1,
          loading: true,
          items_side: [
            {title: 'Reports'},
            {title: 'Individuals'},
            {title: 'Publications'},
            {title: 'Variants'},
          ]
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
          console.log(apiUrl);
          try {
            let response = await this.axios.get(apiUrl);
            console.log(response);
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