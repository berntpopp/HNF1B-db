<template>
  <v-container fluid>
    <v-row>
      <v-col cols="12">
        <v-sheet outlined>
          <!-- Tabs section -->
          <v-tabs v-model="tab">
            <v-tab v-for="item in items" :key="item.tab">
              {{ item.tab }}
            </v-tab>
          </v-tabs>

          <v-tabs-items v-model="tab">
            <v-tab-item v-for="item in items" :key="item.tab">
              <v-card flat>
                <v-card-text>
                  <component v-bind:is="item.content"></component>
                </v-card-text>
              </v-card>
            </v-tab-item>
          </v-tabs-items>
          <!-- Tabs section -->
        </v-sheet>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
import VariantVsScoreBoxPlot from "@/components/analyses/VariantVsScoreBoxPlot.vue";
import PublicationsPlot from "@/components/analyses/PublicationsPlot.vue";

export default {
  name: "AnalysisGenotypePhenotype",
  components: {
    VariantVsScoreBoxPlot,
    PublicationsPlot,
  },
  data() {
    return {
      tab: null,
      items: [
        { tab: "Variant attributes vs. phenoytpe score", content: "VariantVsScoreBoxPlot" },
      ],
    };
  },
  computed: {},
  mounted() {},
  methods: {},
};
</script>