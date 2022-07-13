<template>
  <v-app id="hnf1b-db">
    <v-app-bar app>
      <v-toolbar-title>
        <v-btn x-large to="/">
          <v-img
            src="../public/HNF1B-db_logo.png"
            max-width="184"
            max-height="40"
            alt="HNF1B database logo"
          >
            <template v-slot:placeholder>
              <v-row class="fill-height ma-0" align="center" justify="center">
                <v-progress-circular
                  indeterminate
                  color="grey lighten-5"
                ></v-progress-circular>
              </v-row>
            </template>
          </v-img>
        </v-btn>
      </v-toolbar-title>

      <v-spacer></v-spacer>

      <v-toolbar-items class="hidden-sm-and-down">
        <v-menu offset-y>
          <template v-slot:activator="{ on }">
            <v-btn :ripple="false" text v-on="on"> Tables </v-btn>
          </template>

          <v-card>
            <v-list dense>
              <v-list-item
                v-for="table in tables"
                :key="`notification-key-${table.id}`"
                :to="table.to"
                link
              >
                <v-list-item-title>
                  {{ table.title }}
                </v-list-item-title>
              </v-list-item>
            </v-list>
          </v-card>
        </v-menu>

        <v-menu offset-y>
          <template v-slot:activator="{ on }">
            <v-btn :ripple="false" text v-on="on"> Analyses </v-btn>
          </template>

          <v-card>
            <v-list dense>
              <v-list-item
                v-for="analysis in analyses"
                :key="`notification-key-${analysis.id}`"
                :to="analysis.to"
                link
              >
                <v-list-item-title>
                  {{ analysis.title }}
                </v-list-item-title>
              </v-list-item>
            </v-list>
          </v-card>
        </v-menu>

        <v-btn
          :ripple="false"
          text
          v-for="item in items"
          :key="item.title"
          :to="item.to"
        >
          {{ item.title }}
        </v-btn>
      </v-toolbar-items>

      <!-- // collapsed toolbar for small screen devices //-->
      <v-toolbar-items class="hidden-md-and-up">
        <v-menu offset-y>
          <template v-slot:activator="{ on }">
            <v-btn :ripple="false" text v-on="on">
              <v-icon dark right> mdi-dots-vertical </v-icon>
            </v-btn>
          </template>

          <v-card>
            <v-list dense>
              <v-list-item
                v-for="item in items_small"
                :key="`notification-key-${item.id}`"
                :to="item.to"
                link
              >
                <v-list-item-title>
                  {{ item.title }}
                </v-list-item-title>
              </v-list-item>
            </v-list>
          </v-card>
        </v-menu>
      </v-toolbar-items>
      <!-- // collapsed toolbar for small screen devices //-->
    </v-app-bar>

    <v-main class="grey lighten-3">
      <router-view></router-view>
    </v-main>

    <v-footer padless>
      <v-card-text class="text-center">
        <v-btn
          :ripple="false"
          v-for="footer_item in footer_items"
          :key="footer_item.icon"
          class="mx-4"
          icon
          :href="footer_item.to"
          :target="footer_item.target"
          :aria-label="footer_item.icon"
        >
          <v-icon aria-hidden="true" size="24px">
            {{ footer_item.icon }}
          </v-icon>
        </v-btn>
      </v-card-text>
    </v-footer>
  </v-app>
</template>


<script>
export default {
  data: () => ({
    items: [
      { title: "About", to: "/about", id: "about" },
    ],
    items_small: [
      { title: "Individuals", to: "/table_individuals", id: "table 1" },
      { title: "Reports", to: "/table_reports", id: "table 2" },
      { title: "Publications", to: "/table_publications", id: "table 3" },
      { title: "Variants", to: "/table_variants", id: "table 4" },
      { title: "Cohort", to: "/analysis_cohort", id: "analysis 1" },
      {
        title: "Individuals",
        to: "/analysis_genotype_phenotype",
        id: "analysis 2",
      },
      { title: "About", to: "/about", id: "about" },
    ],
    tables: [
      { title: "Individuals", to: "/table_individuals", id: "table 1" },
      { title: "Reports", to: "/table_reports", id: "table 2" },
      { title: "Publications", to: "/table_publications", id: "table 3" },
      { title: "Variants", to: "/table_variants", id: "table 4" },
    ],
    analyses: [
      {
        title: "Cohort characteristics",
        to: "/analysis_cohort",
        id: "analysis 1",
      },
      {
        title: "Genotype phenotype",
        to: "/analysis_genotype_phenotype",
        id: "analysis 2",
      },
    ],
    footer_items: [
      {
        icon: "mdi-github",
        to: "https://github.com/berntpopp/HNF1B-db",
        target: "_blank",
      },
      { icon: "mdi-api", to: "/api/__docs__/", target: "_self" },
      {
        icon: "mdi-copyright",
        to: "https://creativecommons.org/licenses/by/4.0/",
        target: "_blank",
      },
    ],
  }),
};
</script>
