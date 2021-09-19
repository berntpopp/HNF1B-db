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
              <div class="text-lg-h6 pa-2">
                HNF1b-db
              </div>
              <div class="text-justify pa-2">
                Pathogenic variants in the <span class="font-italic">HNF1B</span>-gene are associated with a variety of inherited kidney diseases ranging from renal cysts and diabetes syndrome (RCAD) and CAKUT to autosomal dominant tubulointerstitial kidney disease (ADTKD). In addition, variable extrarenal manifestations, such as abnormalities of the genital tract (vaginal aplasia, uterus malformation), gout, pancreatic insufficiency, electrolyte abnormalities, liver disease, neurodevelopmental and neuropsychological disorders have been linked to <span class="font-italic">HNF1B </span>-defects (MIM #189907).
              </div>
              <div class="text-justify pa-2">
                To standardize the clinical and genetic spectrum, we curated a list of 30 clinical features associated with <span class="font-italic">HNF1B </span>-disease based on HPO-terms. We then developed a HNF1B-db as web-based application and database to store and share this data.The HNF1b-db currently contains <span class="font-weight-bold"> 968 individuals </span> from <span class="font-weight-bold"> 152 reviewed publications </span>.
              </div>
            </v-sheet>
          </v-col>

        </v-row>
      </v-container>
</template>

<script>

  export default {
    name: 'Home',

  }
</script>
