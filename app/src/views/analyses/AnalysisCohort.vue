<template>
       <v-container>
        <v-row>
          <v-col
            cols="12"
          >

            <v-sheet
              min-height="70vh"
              outlined
            >

      <!-- Tabs section -->
            <v-tabs v-model="tab" background-color="primary" dark>
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
import PhenotypePlot from '@/components/PhenotypePlot.vue';
import PublicationsPlot from '@/components/PublicationsPlot.vue';
import CohortPlot from '@/components/CohortPlot.vue';

  export default {
    name: 'CohortCharacteristics',
    components: {
      PhenotypePlot,
      PublicationsPlot,
      CohortPlot
    },
  data() {
        return {
          tab: null,
          items: [
            { tab: 'Publications', content: 'PublicationsPlot' },
            { tab: 'Phenotype', content: 'PhenotypePlot' },
            { tab: 'Cohort', content: 'CohortPlot' }
          ],
        }
      },
      computed: {
      },
      mounted() {
      },
      methods: {

    }

  }
</script>