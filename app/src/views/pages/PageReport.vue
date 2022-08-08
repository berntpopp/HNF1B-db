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
              Report:
              <v-chip color="deep-orange lighten-2" class="ma-2">
                rep{{ $route.params.report_id }}
                <v-icon right> {{ icons.mdiNewspaperVariant }} </v-icon>
              </v-chip>
            </h3>
          </div>

          <v-list-item>
            <v-list-item-content>
              <v-list-item-title class="text-h5">
                <v-chip color="lime lighten-2" class="ma-2" small>
                  ind{{ report[0].individual_id }}
                  <v-icon right> {{ icons.mdiAccount }} </v-icon>
                </v-chip>
              </v-list-item-title>

              <v-divider inset> </v-divider>

              <v-list-item>
                Report date: {{ report[0].report_date }}
                <v-spacer></v-spacer>
                Reviewed on: {{ report[0].report_review_date }}
              </v-list-item>

              <v-list-item>
                Age reported: {{ report[0].report_age }}
                <v-spacer></v-spacer>
                Sex reported:
                <v-icon small>
                  {{ sex_symbol[report[0].sex_reported] }}
                </v-icon>
              </v-list-item>

              <v-list-item>
                Age onset: {{ report[0].onset_age }}
                <v-spacer></v-spacer>
                Cohort:
                <v-chip
                  :color="cohort_style[report[0].cohort]"
                  class="ma-2"
                  x-small
                >
                  {{ report[0].cohort }}
                </v-chip>
              </v-list-item>

              <v-list-item>
                Phenotypes:
                <div>
                  <template v-for="phenotype in report[0].phenotypes">
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
        </v-sheet>
      </v-col>
    </v-row>
  </v-container>
</template>


<script>
import colorAndSymbolsMixin from "@/assets/js/mixins/colorAndSymbolsMixin.js";
import { mdiNewspaperVariant, mdiAccount } from '@mdi/js';

export default {
  name: "PageReport",
  mixins: [colorAndSymbolsMixin],
  data() {
    return {
      icons: {
        mdiNewspaperVariant,
        mdiAccount,
      },
      report: [
        {
          report_id: null,
          report_date: null,
          report_user_id: null,
          report_review_date: null,
          individual_id: null,
          sex_reported: null,
          reported_multiple: null,
          cohort: null,
          onset_prenatal: null,
          onset_age: null,
          report_prenatal: null,
          report_age: null,
        },
      ],
      absolute: true,
      opacity: 1,
      color: "#FFFFFF",
      loading: true,
    };
  },
  computed: {},
  created() {
    this.loadReportData();
  },
  mounted() {},
  methods: {
    async loadReportData() {
      this.loading = true;

      let apiUrl =
        process.env.VUE_APP_API_URL +
        "/api/reports?filter=equals(report_id," +
        this.$route.params.report_id +
        ")";

      try {
        let response = await this.axios.get(apiUrl);

        // redirect to 404 if response is empty data
        if (response.data.data.length === 0) {
          this.$router.push("/PageNotFound");
        } else {
          this.report = response.data.data;
        }
      } catch (e) {
        console.error(e);
      }
      this.loading = false;
    },
  },
};
</script>