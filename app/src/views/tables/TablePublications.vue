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
                >

                  <template v-slot:[`item.publication_id`]="{ item }">
                    <v-chip
                      color="cyan accent-2"
                      class="ma-2"
                      x-small
                      link
                      :to="'/publication/' + item.publication_id"
                    >
                      pub{{ item.publication_id }}
                      <v-icon right>
                        mdi-book-open-blank-variant
                      </v-icon>
                    </v-chip>
                  </template>

                  <template v-slot:[`item.PMID`]="{ item }">
                    <a
                      :href="'https://pubmed.ncbi.nlm.nih.gov/' + item.PMID"
                      target="_blank"
                    >
                      {{ item.PMID }}
                    </a>
                  </template>

                  <template v-slot:[`item.DOI`]="{ item }">
                    <a
                      :href="'https://doi.org/' + item.DOI"
                      target="_blank"
                    >
                      {{ item.DOI }}
                    </a>
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
  name: 'TablePublications',
  data() {
        return {
          publications: [],
          headers:[
            { text:'Publication', value: 'publication_id' },
            { text:"Type", value:"publication_type" },
            { text:"PMID", value:"PMID" },
            { text:"DOI", value:"DOI" },
            { text:"First Author", value:"firstauthor_lastname" },
            { text:"Journal", value:"journal" },
            { text:"Date", value:"publication_date" }
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
        this.loadPublicationsData();
      },
      methods: {
        async loadPublicationsData() {
          this.loading = true;
          let apiUrl = process.env.VUE_APP_API_URL + '/api/publications';
          try {
            let response = await this.axios.get(apiUrl);

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