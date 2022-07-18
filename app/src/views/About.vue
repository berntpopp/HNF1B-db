<template>
  <v-container fluid>
    <v-row>
      <v-col cols="12" sm="12">
        <v-sheet outlined>
          <div class="pa-2">
            <v-expansion-panels inset v-model="panel">
              <v-expansion-panel
                v-for="item in about_content"
                :key="item.index"
              >
                <v-expansion-panel-header>
                  {{ item.title }}
                </v-expansion-panel-header>
                <v-expansion-panel-content>
                  {{ item.body }}
                </v-expansion-panel-content>
              </v-expansion-panel>
            </v-expansion-panels>
          </div>
        </v-sheet>
      </v-col>
    </v-row>
  </v-container>
</template>


<script>
export default {
  name: "About",
  metaInfo: {
    // if no subcomponents specify a metaInfo.title, this title will be used
    title: "About",
    // all titles will be injected into this template
    titleTemplate:
      "%s | HNF1B-db - The curated database for the HNF1B gene and associated diseases",
    htmlAttrs: {
      lang: "en",
    },
    meta: [
      {
        vmid: "description",
        name: "description",
        content: "This is the About page of HNF1B-db.",
      },
    ],
  },
  data: () => ({
    panel: 0,
    about_content: [
      {
        title: "About HNF1B-db",
        index: 0,
        body: "To standardize our own cohort and curate the clinical and genetic spectrum from the literature, we curated a list of 30 clinical features associated with HNF1B-disease based on HPO-terms. Next, we developed a web-based application (available at HNF1B.org or hnf1b.uni-leipzig.de) for comprehensive data input and analysis from patient histories or published literature within the time span from 1997 to 2020.",
      },
      {
        title: "The HNF1B gene",
        index: 1,
        body: 'Pathogenic variants in the <span class="font-italic">HNF1B</span>-gene are associated with a variety of inherited kidney diseases ranging from renal cysts and diabetes syndrome (RCAD) and CAKUT to autosomal dominant tubulointerstitial kidney disease (ADTKD). In addition, variable extrarenal manifestations, such as abnormalities of the genital tract (vaginal aplasia, uterus malformation), gout, pancreatic insufficiency, electrolyte abnormalities, liver disease, neurodevelopmental and neuropsychological disorders have been linked to <span class="font-italic">HNF1B </span>-defects (MIM #189907).',
      },
      {
        title: "Citation policy",
        index: 2,
        body: "<p>In addition to this website, the review concept and variants represented in HNF1B-db have partially been described in this publication: </p> <p> Vasileiou G, Hoyer J, Thiel CT, Schaefer J, Zapke M, Krumbiegel M, Kraus C, Zweier M, Uebe S, Ekici AB, Schneider M, Wiesener M, Rauch A, Faschingbauer F, Reis A, Zweier C, Popp B. Prenatal diagnosis of HNF1B-associated renal cysts: Is there a need to differentiate intragenic variants from 17q12 microdeletion syndrome? Prenat Diagn. 2019 Nov;39(12):1136-1147. doi: 10.1002/pd.5556. Epub 2019 Oct 25. PMID: 31498910. </p> <p> We are currently working on a manuscript describing the curation effort and development of HNF1B-db. Until then please cite above publication if you use HNF1B-db in your work. </p>",
      },
      {
        title: "News and Updates",
        index: 3,
        body: "2021-09-18: HNF1B-db is currently in alpha development status and changes rapidely.",
      },
      {
        title: "Help and FAQ",
        index: 4,
        body: "Here we will present Help and FAQ once the website and API functionallity is complete..",
      },
    ],
  }),
  created() {},
  mounted() {
    this.removeWrongAria();
  },
  methods: {
    removeWrongAria() {
      // select all elements with the class v-expansion-panel
      let expPanelsArr = document.querySelectorAll(".v-expansion-panel");
      // remove the wrongly set aria-expanded attribute
      for (let i = 0; i < expPanelsArr.length; i++) {
        if (expPanelsArr[i]) {
          expPanelsArr[i].removeAttribute("aria-expanded");
        }
      }
    },
  },
};
</script>