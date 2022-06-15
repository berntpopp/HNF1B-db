<template>
       <v-container fluid>
        <v-row>

          <v-col
            cols="12"
            sm="12"
          >

            <v-sheet
              min-height="80vh"
              outlined
              class="px-2"
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
              <h3>Variant: 
                <v-chip
                  color="pink lighten-4"
                  class="ma-2"
                >
                  var{{ $route.params.variant_id }}
                  <v-icon right>
                    mdi-dna
                  </v-icon>
                </v-chip>
              </h3>
            </div>
  

  <v-card
    class="mx-auto px-2 py-2"
    elevation="8"
    outlined
  >
 
      <v-data-table
      dense
      :items="variant"
      :headers="headers"
      item-key="variant_id"
      class="elevation-1"
      mobile-breakpoint="1200"
      disable-pagination
      hide-default-footer
    >

      <template v-slot:[`item.variant_class`]="{ item }">
        <v-chip
          class="ma-1"
          small
        >
          {{ item.variant_class }}
        </v-chip>
        <v-chip
          class="ma-1"
          small
        >
          {{ item.IMPACT }}
        </v-chip>
      </template>

      <template v-slot:[`item.HGVS_C`]="{ item }">
          {{ item.HGVS_C }}, {{ item.HGVS_P }}
      </template>

      <template v-slot:[`item.criteria_classification`]="{ item }">
            <v-chip
              small
              class="ma-1"
              v-for="criterion in item.criteria_classification"
              :key="`criterion-list-${criterion}`"
              color="orange lighten-4"
            >
              {{ criterion }}
            </v-chip>
      </template>

    </v-data-table>

  </v-card>

            </v-sheet>
          </v-col>

        </v-row>
      </v-container>
</template>


<script>
export default {
  name: 'PageVariant',
  data() {
        return {
          variant: [
            {
              "variant_id": null,
              "variant_report_status": null,
              "variant_annotation_source": null,
              "variant_annotation_date": null,
              "variant_class": null,
              "vcf_hg19": null,
              "ID": null,
              "INFO_hg19": null,
              "FEATUREID": null,
              "HGVS_C": null,
              "HGVS_P": null,
              "reports": null
            }
          ],
          headers:[
            { text:'Annotation date', value: 'variant_annotation_date', sortable: false},
            { text:'Type', value: 'variant_class', sortable: false},
            { text:'Effect', value: 'EFFECT', sortable: false},
            { text:'Transcript', value: 'FEATUREID', sortable: false},
            { text:'HGVS', value: 'HGVS_C', sortable: false},
            { text:'VCF', value: 'vcf_hg19', sortable: false},
            { text:'Verdict classification', value: 'verdict_classification', sortable: false},
            { text:'Criteria classification', value: 'criteria_classification', sortable: false},
          ],
          absolute: true,
          opacity: 1,
          color: "#FFFFFF",
          loading: true,
          reported_phenotype_color: {"yes": "teal lighten-1", "no": "light-blue", "not reported": "white"},
          reported_phenotype_symbol: {"yes": "mdi-plus-circle-outline", "no": "mdi-minus-circle-outline", "not reported": "mdi-help-circle-outline"},
          sex_symbol: {"female": "mdi-gender-female", "male": "mdi-gender-male", "unspecified": "mdi-help-circle-outline"},
          cohort_style: {"born": "success", "fetus": "primary"},
        }
      },
      computed: {
      },
      created() {
      },
      mounted() {
        this.loadVariantData();
      },
      methods: {
        async loadVariantData() {
          this.loading = true;

          let apiUrl = process.env.VUE_APP_API_URL + '/api/variants?filter=equals(variant_id,' + this.$route.params.variant_id + ')';

          try {
            let response = await this.axios.get(apiUrl);
            this.variant = response.data.data;
            console.log(this.variant);


          } catch (e) {
            console.error(e);
          }
          this.loading = false;
        }
      }
  }
</script>


<style>  
.v-data-table__wrapper > table > tbody > tr:hover {
  background: inherit !important;
}
</style>