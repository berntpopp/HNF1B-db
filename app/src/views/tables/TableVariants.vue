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
            Variants Table
            </div>
  
            <p class="text-justify">
              Search and filter the reviewed variants in a tabular view.
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
                  :items="variants"
                  :headers="headers"
                  :search="search"
                  item-key="name"
                  class="elevation-1"
                >

                  <template v-slot:[`item.variant_id`]="{ item }">
                    <v-chip
                      color="pink lighten-4"
                      class="ma-2"
                      x-small
                      link
                      :to="'/variant/' + item.variant_id"
                    >
                      var{{ item.variant_id }}
                    <v-icon right>
                        mdi-dna
                      </v-icon>
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
  name: 'TableVariants',
  data() {
        return {
          variants: [],
          headers:[
            { text:'Variant', value: 'variant_id' },
            { text:"Type", value:"variant_class" },
            { text:"VCF", value:"vcf_hg19" },
            { text:"Transcript", value:"HGVS_C" },
            { text:"Protein", value:"HGVS_P" }
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
        this.loadVariantsData();
      },
      methods: {
        async loadVariantsData() {
          this.loading = true;
          let apiUrl = process.env.VUE_APP_API_URL + '/api/variants';
          try {
            let response = await this.axios.get(apiUrl);
            this.variants = response.data.data;
            this.totalRows = response.data.data.length;
          } catch (e) {
            console.error(e);
          }
          this.loading = false;
        }
      }
  }
</script>