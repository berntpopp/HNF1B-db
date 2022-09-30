<template>
  <v-container fluid>
    <v-row>
      <v-col cols="12" sm="12">
        <v-sheet outlined>
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
              Individual:
              <v-chip color="lime lighten-2" class="ma-2">
                ind{{ $route.params.individual_id }}
                <v-icon right> {{ icons.mdiAccount }} </v-icon>
              </v-chip>
            </h3>
          </div>

          <v-card
            class="mx-auto my-2"
            max-width="800"
            v-for="item in individual.reports"
            :key="item.report_id"
          >
            <v-list-item>
              <v-list-item-content>
                <v-list-item-title class="text-h5">
                  Report:
                  <v-chip color="deep-orange lighten-2" class="ma-2" small>
                    rep{{ item.report_id }}
                    <v-icon right> {{ icons.mdiNewspaperVariant }} </v-icon>
                  </v-chip>
                </v-list-item-title>

                <v-divider inset> </v-divider>

                <v-list-item>
                  Report date: {{ item.report_date }}
                  <v-spacer></v-spacer>
                  Reviewed on: {{ item.report_review_date }}
                </v-list-item>

                <v-list-item>
                  Age reported: {{ item.report_age }}
                  <v-spacer></v-spacer>
                  Sex reported:
                  <v-icon small>
                    {{ sex_symbol[item.sex_reported] }}
                  </v-icon>
                </v-list-item>

                <v-list-item>
                  Age onset: {{ item.onset_age }}
                  <v-spacer></v-spacer>
                  Cohort:
                  <v-chip
                    :color="cohort_style[item.cohort]"
                    class="ma-2"
                    x-small
                  >
                    {{ item.cohort }}
                  </v-chip>
                </v-list-item>

                <v-list-item>
                  Phenotypes:
                  <div>
                    <template v-for="phenotype in item.phenotypes">
                      <v-chip
                        class="ma-0"
                        x-small
                        :key="phenotype.phenotype_id"
                        :color="reported_phenotype_color[phenotype.described]"
                      >
                        <v-icon x-small>
                          {{ reported_phenotype_symbol[phenotype.described] }}
                        </v-icon>

                        {{ phenotype.phenotype_name }}
                      </v-chip>
                    </template>
                  </div>
                </v-list-item>
              </v-list-item-content>
            </v-list-item>
          </v-card>

          <v-card-text class="d-flex justify-center">
            <!-- Load Variants table component element -->
            <template v-if="!loading">
              <TableVariants
                :show-filter-controls="false"
                :show-pagination-controls="false"
                :filter-input="variant_of_individual_filter"
                header-label="Variants"
                header-sub-label="identified in this individual"
              />
            </template>
            <!-- Load Variants table component element -->
          </v-card-text>
        </v-sheet>
      </v-col>
    </v-row>
  </v-container>
</template>


<script>
import TableVariants from "@/components/tables/TableVariants.vue";

import colorAndSymbolsMixin from "@/assets/js/mixins/colorAndSymbolsMixin.js";

export default {
  name: "PageIndividual",
  mixins: [colorAndSymbolsMixin],
  components: {
    TableVariants,
  },
  data() {
    return {
      individual: {},
      absolute: true,
      opacity: 1,
      color: "#FFFFFF",
      loading: true,
      variant_of_individual_filter: "",
    };
  },
  computed: {},
  created() {
    this.loadIndividualData();
  },
  mounted() {},
  methods: {
    async loadIndividualData() {
      this.loading = true;

      let apiUrl =
        process.env.VUE_APP_API_URL +
        "/api/individuals?filter=equals(individual_id," +
        this.$route.params.individual_id +
        ")";

      try {
        let response = await this.axios.get(apiUrl);

        // redirect to 404 if response is empty data
        if (response.data.data.length === 0) {
          this.$router.push("/PageNotFound");
        } else {
          this.individual = response.data.data[0];

          this.variant_of_individual_filter =
            "equals(individual_id," + this.$route.params.individual_id + ")";
        }
      } catch (e) {
        console.error(e);
      }
      this.loading = false;
    },
  },
};
</script>