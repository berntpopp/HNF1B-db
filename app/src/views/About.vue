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
            <div class="pa-2">  
              <v-expansion-panels>
                <v-expansion-panel>
                    <v-expansion-panel-header>About HNF1B-db</v-expansion-panel-header>
                    <v-expansion-panel-content>
                      To standardize our own cohort and curate the clinical and genetic spectrum from the literature, we curated a list of 30 clinical features associated with HNF1B-disease based on HPO-terms. Next, we developed a web-based application (available under curating.HNF1B.org) for comprehensive data input and analysis from patient histories or published literature within the time span from 1997 to 2020.
                    </v-expansion-panel-content>
                  </v-expansion-panel>
                  <v-expansion-panel>
                    <v-expansion-panel-header>Citation policy</v-expansion-panel-header>
                    <v-expansion-panel-content>
                      <p>In addition to this website, the review concept and variants represented in HNF1B-db have partially been described in this publication:</p>
                      <p>Vasileiou G, Hoyer J, Thiel CT, Schaefer J, Zapke M, Krumbiegel M, Kraus C, Zweier M, Uebe S, Ekici AB, Schneider M, Wiesener M, Rauch A, Faschingbauer F, Reis A, Zweier C, Popp B. Prenatal diagnosis of HNF1B-associated renal cysts: Is there a need to differentiate intragenic variants from 17q12 microdeletion syndrome? Prenat Diagn. 2019 Nov;39(12):1136-1147. doi: 10.1002/pd.5556. Epub 2019 Oct 25. PMID: 31498910.</p>
                      <p>We are currently working on a manuscript describing the curation effort and development of HNF1B-db. Until then please cite above publication if you use HNF1B-db in your work.</p>
                    </v-expansion-panel-content>
                  </v-expansion-panel>
                  <v-expansion-panel>
                    <v-expansion-panel-header>News and Updates</v-expansion-panel-header>
                    <v-expansion-panel-content>
                      2021-09-18: HNF1B-db is currently in alpha development status and changes rapidely.
                    </v-expansion-panel-content>
                  </v-expansion-panel>
                  <v-expansion-panel>
                    <v-expansion-panel-header>Help and FAQ</v-expansion-panel-header>
                    <v-expansion-panel-content>
                      Here we will present Help and FAQ once the website and API functionallity is complete.
                    </v-expansion-panel-content>
                </v-expansion-panel>
              </v-expansion-panels>
            </div>
            </v-sheet>
          </v-col>

        </v-row>
      </v-container>
</template>
