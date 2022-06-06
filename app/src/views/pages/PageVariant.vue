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
    class="mx-auto my-2"
    max-width="800"
  >
      <v-list-item>
      <v-list-item-content>

        <v-list-item>
          <v-chip
            class="ma-2"
          >
            {{ variant[0].variant_class }}
          </v-chip>
          <v-chip
            class="ma-2"
          >
            {{ variant[0].IMPACT }}
          </v-chip>
          <v-chip
            class="ma-2"
          >
            {{ variant[0].EFFECT }}
          </v-chip>
        </v-list-item>

        <v-list-item>
          Annotation date: {{ variant[0].variant_annotation_date }}
        </v-list-item>

        <v-divider inset> </v-divider>
            
        <v-list-item>
          <b>Transcript: </b>
          {{ variant[0].FEATUREID }}
        </v-list-item>

        <v-list-item>
          <b>HGVS: </b> {{ variant[0].HGVS_C }}, {{ variant[0].HGVS_P }}
        </v-list-item>

        <v-list-item>
          <b>VCF (hg19): </b> {{ variant[0].vcf_hg19 }}
        </v-list-item>

        <v-list-item>
          <b>INFO (hg19): </b> {{ variant[0].INFO_hg19 }}
        </v-list-item>

        <v-list-item>
          <b>VCF (hg38): </b> {{ variant[0].vcf_hg38 }}
        </v-list-item>

        <v-list-item>
          <b>INFO (hg38): </b> {{ variant[0].INFO_hg38 }}
        </v-list-item>

        <v-list-item>
          <b>Verdict classification: </b> {{ variant[0].verdict_classification }} 
        </v-list-item>

        <v-list-item>
          <b>Criteria classification: </b> 
            <v-chip
              v-for="criterion in variant[0].criteria_classification"
              :key="`criterion-list-${criterion}`"
                  color="orange lighten-4"
            >
                {{ criterion }}
            </v-chip>
          
        </v-list-item>

      </v-list-item-content>
    </v-list-item>

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
        this.loadVariantData();
      },
      mounted() {
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