<template>
  <v-container fluid>
    <v-row>
      <v-col cols="12" sm="12">
        <v-sheet outlined class="px-2">
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

          <div class="text-lg-h6">
            <h3>
              Variant:
              <v-chip color="pink lighten-4" class="ma-2">
                var{{ $route.params.variant_id }}
                <v-icon right> {{ icons.mdiDna }} </v-icon>
              </v-chip>
            </h3>
          </div>

          <v-card class="mx-auto px-2 py-2" elevation="8" outlined>
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
                  :color="variant_class_color[item.variant_class]"
                >
                  {{ item.variant_class }}
                </v-chip>
                <v-chip class="ma-1" small :color="impact_color[item.IMPACT]">
                  {{ item.IMPACT }}
                </v-chip>
              </template>

              <template v-slot:[`item.HGVS_C`]="{ item }">
                {{ item.HGVS_C }}, {{ item.HGVS_P }}
              </template>

              <template v-slot:[`item.verdict_classification`]="{ item }">
                <v-chip
                  small
                  class="ma-1"
                  :color="classification_color[item.verdict_classification]"
                >
                  {{ item.verdict_classification }}
                </v-chip>
              </template>

              <template v-slot:[`item.criteria_classification`]="{ item }">
                <v-chip
                  small
                  class="ma-1"
                  v-for="criterion in item.criteria_classification"
                  :key="`criterion-list-${criterion}`"
                  :color="
                    criteria_color[criterion.charAt(0)][criterion.split('_')[1]]
                  "
                >
                  {{ criterion }}
                </v-chip>
              </template>
            </v-data-table>

            <v-card-text class="d-flex justify-center">
              <!-- Load Protein linear plot component -->
              <ProteinLinearPlot
                :show_controls="false"
                :variant_filter="
                  'equals(variant_id,' + this.$route.params.variant_id + ')'
                "
              >
              </ProteinLinearPlot>
              <!-- Load Protein linear plot component -->
            </v-card-text>

            <v-card-text class="d-flex justify-center">
              <!-- Load Individuals table component element -->
              <template v-if="!loading">
                <TableIndividuals
                  :show-filter-controls="false"
                  :show-pagination-controls="false"
                  :filter-input="individuals_with_variant_filter"
                  header-label="Individuals"
                  header-sub-label="carrying this variant"
                />
              </template>
              <!-- Load Individuals table component element -->
            </v-card-text>
          </v-card>
        </v-sheet>
      </v-col>
    </v-row>
  </v-container>
</template>


<script>
import ProteinLinearPlot from "@/components/analyses/ProteinLinearPlot.vue";
import TableIndividuals from "@/components/tables/TableIndividuals.vue";

import colorAndSymbolsMixin from "@/assets/js/mixins/colorAndSymbolsMixin.js";

export default {
  name: "PageVariant",
  mixins: [colorAndSymbolsMixin],
  components: {
    ProteinLinearPlot,
    TableIndividuals,
  },
  data() {
    return {
      variant: [
        {
          variant_id: null,
          variant_annotation_source: null,
          variant_annotation_date: null,
          variant_class: null,
          vcf_hg19: null,
          ID: null,
          INFO_hg19: null,
          FEATUREID: null,
          HGVS_C: null,
          HGVS_P: null,
          reports: null,
        },
      ],
      headers: [
        {
          text: "Annotation date",
          value: "variant_annotation_date",
          sortable: false,
        },
        { text: "Type", value: "variant_class", sortable: false },
        { text: "Effect", value: "EFFECT", sortable: false },
        { text: "Transcript", value: "FEATUREID", sortable: false },
        { text: "HGVS", value: "HGVS_C", sortable: false },
        { text: "VCF [hg19]", value: "vcf_hg19", sortable: false },
        {
          text: "Verdict classification",
          value: "verdict_classification",
          sortable: false,
        },
        {
          text: "Criteria classification",
          value: "criteria_classification",
          sortable: false,
        },
      ],
      absolute: true,
      opacity: 1,
      color: "#FFFFFF",
      loading: true,
      individuals_with_variant: [],
      individuals_with_variant_filter: "",
    };
  },
  computed: {},
  created() {
    this.loadVariantData();
  },
  mounted() {},
  methods: {
    async loadVariantData() {
      this.loading = true;

      let apiUrl =
        process.env.VUE_APP_API_URL +
        "/api/variants?sort=variant_id&fields=variant_id,variant_annotation_source,variant_annotation_date,variant_class,vcf_hg19,ID,INFO_hg19,FEATUREID,HGVS_C,HGVS_P,IMPACT,EFFECT,Protein_position,CADD_PHRED,verdict_classification,criteria_classification,reports&page_after=0&page_size=all&filter=equals(variant_id," +
        this.$route.params.variant_id +
        ")";

      try {
        let response = await this.axios.get(apiUrl);

        // redirect to 404 if response is empty data
        if (response.data.data.length === 0) {
          this.$router.push("/PageNotFound");
        } else {
          this.variant = response.data.data;

          this.individuals_with_variant = [
            ...new Set(
              response.data.data[0].reports.map((item) => item.individual_id)
            ),
          ];
          this.individuals_with_variant_filter =
            "contains(individual_id," +
            this.individuals_with_variant.join("|") +
            ")";
        }
      } catch (e) {
        console.error(e);
      }
      this.loading = false;
    },
  },
};
</script>


<style>
.v-data-table__wrapper > table > tbody > tr:hover {
  background: inherit !important;
}
</style>