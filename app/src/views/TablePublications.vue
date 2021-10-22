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

            <div 
              class="text-lg-h6"
            >
            Publications Table
            </div>
  
            <p class="text-justify">
              Search and filter the reviewed publications in a tabular view.
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
                  :items="publications"
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
          publications: [],
          headers:[
            { text:'Publication', value: 'publication_id'  },
            { text:"Type", value:"publication_type" },
            { text:"PMID", value:"PMID" },
            { text:"DOI", value:"DOI" },
            { text:"First Author", value:"firstauthor_lastname" },
            { text:"journal", value:"journal" },
            { text:"Date", value:"publication_date" }
          ],
          search: '',
          totalRows: 1,
          loading: true
        }
      },
      computed: {
      },
      mounted() {
        this.loadPublicationsData();
      },
      methods: {
        async loadPublicationsData() {
          this.loading = true;
          let apiUrl = process.env.VUE_APP_API_URL + '/api/publications';
          console.log(apiUrl);
          try {
            let response = await this.axios.get(apiUrl);
            console.log(response);
            this.publications = response.data.data;
            this.totalRows = response.data.data.length;
          } catch (e) {
            console.error(e);
          }
          this.loading = false;
        }
      }
  }
</script>